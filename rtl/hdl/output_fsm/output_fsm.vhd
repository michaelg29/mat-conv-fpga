
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- constants package
library mat_conv_pkg_library;
use mat_conv_pkg_library.mat_conv_pkg.all;

-----------------------
-- Output FSM entity --
-----------------------
entity output_fsm is
  generic (
    -- module configuration
    G_NUM_CLUSTERS   : integer := 4; -- number of clusters
    G_CMP_LATENCY    : integer := 7  -- clock cycle latency for cluster computation
  );
  port (
    -- clock and reset interface
    i_macclk         : in  std_logic;
    i_rst_n          : in  std_logic;
    i_por_n          : in  std_logic;

    -- input FSM
    i_cmd_err        : in  std_logic;
    i_cmd_valid      : in  std_logic;
    i_cmd_subj       : in  std_logic;
    i_payload_done   : in  std_logic;
    i_prepad_done    : in  std_logic;

    -- clusters
    i_output_valid   : in  std_logic_vector(G_NUM_CLUSTERS-1 downto 0);

    -- global memory
    i_ack_ar_rvalid  : in  std_logic;
    i_reg_ar1_rvalid : in  std_logic;
    o_accept_reg_cw1 : out std_logic;
    o_ack_ar_addr    : out std_logic_vector(2 downto 0);
    o_ack_ar_ren     : out std_logic;
    o_reg_ar1_ren    : out std_logic;
    o_reg_ar1_addr   : out std_logic;

    -- output FIFO
    i_buf_empty      : in  std_logic;
    o_fifo_accept_w  : out std_logic_vector(1 downto 0);

    -- AXI Transmitter
    o_new_addr       : out std_logic;

    -- global status
    o_output_written : out std_logic;

    -- external interface
    o_mat_conv_int   : out std_logic
  );
end output_fsm;

---------------------------
-- Main RTL architecture --
---------------------------
architecture rtl of output_fsm is

  ----------------------
  -- STATE DEFINITION --
  ----------------------
  type OUTPUT_FSM_STATE_T is (
    FSM_RESTART,
    WAIT_PAYLOAD,
    SET_OUT_ADDR,
    PAYLOAD_TX,
    SET_TX_ADDR,
    ACK_TX
  );
  signal output_fsm_state : OUTPUT_FSM_STATE_T;

  -- write activation buffer
  signal fifo_accept_w0_buf : std_logic_vector(G_CMP_LATENCY downto 0);

  -- read counter
  signal ack_rvalid_past    : std_logic;
  signal ack_word_cnt       : unsigned(2 downto 0);
  constant ack_word_incr    : unsigned(2 downto 0) := to_unsigned(1, 3);

begin

  -- constant assignments
  o_fifo_accept_w(0) <= fifo_accept_w0_buf(0);
  o_ack_ar_addr      <= std_logic_vector(ack_word_cnt);

  ------------------
  -- Main Process --
  ------------------
  p_main : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0' or i_por_n = '0') then
        -- reset external interface
        o_accept_reg_cw1   <= '0';
        o_ack_ar_ren       <= '0';
        o_reg_ar1_addr     <= '0';
        o_reg_ar1_ren      <= '0';
        o_fifo_accept_w(1) <= '0';
        o_new_addr         <= '0';
        o_output_written   <= '0';
        o_mat_conv_int     <= '0';

        -- reset internal signals
        output_fsm_state   <= WAIT_PAYLOAD;
        fifo_accept_w0_buf <= (others => '0');
        ack_rvalid_past    <= '0';
        ack_word_cnt       <= (others => '1');
      else
        -- shift register fifo_accept_w0_buf
        fifo_accept_w0_buf(G_CMP_LATENCY) <= i_prepad_done;
        fifo_accept_w0_buf(G_CMP_LATENCY-1 downto 0) <= fifo_accept_w0_buf(G_CMP_LATENCY downto 1);

        -- calculate new state
        case (output_fsm_state) is

          -- initial state
          when FSM_RESTART =>
            -- reset external interface
            o_accept_reg_cw1   <= '0';
            o_ack_ar_ren       <= '0';
            o_reg_ar1_addr     <= '0';
            o_reg_ar1_ren      <= '0';
            o_fifo_accept_w(1) <= '0';
            o_output_written   <= '0';
            o_new_addr         <= '0';
            o_mat_conv_int     <= '0';

            -- reset internal signals
            fifo_accept_w0_buf(G_CMP_LATENCY) <= i_prepad_done;
            ack_rvalid_past    <= '0';
            ack_word_cnt       <= (others => '1');

            -- transition
            output_fsm_state <= WAIT_PAYLOAD;

          -- waiting for payload reception
          when WAIT_PAYLOAD =>
            -- transition on command completion
            if (i_cmd_subj = '1') then
              -- valid command
              output_fsm_state <= SET_OUT_ADDR;
              o_reg_ar1_addr   <= '0';
              o_reg_ar1_ren    <= '1';
              o_new_addr       <= '1';
            elsif (i_cmd_err <= '1') then
              -- erroneous command
              output_fsm_state <= SET_TX_ADDR;
              o_reg_ar1_addr   <= '1';
              o_reg_ar1_ren    <= '1';
              o_new_addr       <= '1';
            end if;

          -- set the output address
          when SET_OUT_ADDR =>
            o_reg_ar1_ren <= '0';

            -- transition on complete read
            if (i_reg_ar1_rvalid = '1') then
              o_new_addr       <= '0';
              output_fsm_state <= PAYLOAD_TX;
            else
              o_new_addr       <= '1';
            end if;

          -- payload reception and transmission
          when PAYLOAD_TX =>
            o_fifo_accept_w(1) <= '0';
            -- transition on processing error or transmission completion
            if (((i_cmd_err or i_payload_done) and i_buf_empty) = '1') then
              -- get acknowledge packet address
              output_fsm_state <= SET_TX_ADDR;
              o_reg_ar1_addr   <= '1';
              o_reg_ar1_ren    <= '1';
              o_new_addr       <= '1';
            end if;
            o_output_written <= i_payload_done and i_buf_empty;

          -- set the acknowledge address
          when SET_TX_ADDR =>
            o_reg_ar1_ren <= '0';

            -- transition on complete read
            if (i_reg_ar1_rvalid = '1') then
              o_new_addr       <= '0';
              output_fsm_state <= ACK_TX;
            else
              o_new_addr       <= '1';
            end if;

          -- transmit the acknowledge packet
          when ACK_TX =>
            if ((i_cmd_valid or i_cmd_err) = '1') then
              if (ack_word_cnt = "111") then
                o_ack_ar_ren <= '0';
              else
                o_fifo_accept_w(1) <= '1';
                o_ack_ar_ren       <= '1';
                ack_word_cnt       <= ack_word_cnt + ack_word_incr;
              end if;
            end if;

            -- latch a valid read from the acknowledge buffer
            if (i_ack_ar_rvalid = '1') then
              ack_rvalid_past <= '1';
            end if;

            -- wait for all acknowledge packets to be written
            if ((ack_rvalid_past and i_buf_empty) = '1') then
              o_mat_conv_int   <= '1';
              output_fsm_state <= FSM_RESTART;
            end if;

          -- unknown state
          when others =>
            output_fsm_state <= FSM_RESTART;

        end case;
      end if;
    end if;
  end process p_main;

end rtl;
