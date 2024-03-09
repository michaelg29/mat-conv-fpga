
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- constants package
library mat_conv_pkg_library;
use mat_conv_pkg_library.mat_conv_pkg.all;

----------------------
-- Input FSM entity --
----------------------
entity input_fsm is
  generic (
    -- packet widths
    G_DATA_PKT_WIDTH   : integer := 64; -- width of an AXI data packet
    G_ADDR_PKT_WIDTH   : integer := 8   -- required relative address size
  );
  port (
    -- clock and reset interface
    i_macclk          : in  std_logic;
    i_rst_n           : in  std_logic;
    i_por_n           : in  std_logic;

    -- signals to and from Input FIFO
    i_rx_pkt          : in  std_logic;
    i_rx_addr         : in  std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
    i_rx_data         : in  std_logic_vector(G_DATA_PKT_WIDTH-1 downto 0);

    -- signals to and from AXI Receiver
    i_write_blank_ack : in  std_logic;
    o_write_blank_en  : out std_logic;
    o_drop_pkts       : out std_logic;

    -- signals to and from Command Buffer
    i_rdata           : in  std_logic_vector(31 downto 0);
    i_rvalid          : in  std_logic;
    i_state_reg_pls   : in  std_logic;
    o_addr            : out std_logic_vector( 2 downto 0);
    o_ren             : out std_logic;
    o_wen             : out std_logic;
    o_wdata           : out std_logic_vector(31 downto 0);

    -- global status signals
    i_proc_error      : in  std_logic;
    i_res_written     : in  std_logic;
    o_cmd_valid       : out std_logic;
    o_cmd_err         : out std_logic;
    o_cmd_kern        : out std_logic;
    o_cmd_subj        : out std_logic;
    o_cmd_kern_signed : out std_logic;
    o_eor             : out std_logic;
    o_prepad_done     : out std_logic;
    o_payload_done    : out std_logic
  );
end input_fsm;

---------------------------
-- Main RTL architecture --
---------------------------
architecture rtl of input_fsm is

  ----------------------
  -- STATE DEFINITION --
  ----------------------
  type INPUT_FSM_STATE_T is (
    FSM_RESTART,
    WAIT_CMD_S_KEY,
    WAIT_CMD_SIZE,
    WAIT_CMD_TID,
    WAIT_CMD_E_KEY,
    CHECK_CHKSUM,
    PAYLOAD_RX,
    WAIT_RES_TX,
    ACK_STAT_TX,
    WAIT_ERR_ACK
  );
  signal input_fsm_state : INPUT_FSM_STATE_T;

  -- command signals
  signal cur_cmd_chksum      : std_logic_vector(31 downto 0);
  signal cur_cmd_status      : std_logic_vector(MC_STAT_NBITS-1 downto 0);
  signal new_cmd_status      : std_logic_vector(MC_STAT_NBITS-1 downto 0);
  signal cur_cmd_err         : std_logic;
  signal cur_cmd_kern        : std_logic;
  signal cur_cmd_subj        : std_logic;
  signal cur_cmd_kern_signed : std_logic;
  signal cur_cmd_cmplt       : std_logic;

  -- CDC signals
  signal write_blank_ack     : std_logic;

  ----------------------
  -- PAYLOAD COUNTERS --
  ----------------------
  signal exp_cols            : std_logic_vector(3 downto 0); -- 4 bits in the SIZE field of the command
  signal cur_cols            : unsigned( 7 downto 0); -- maximum 11-bit count of columns => maximum 8-bit count of 8-Byte packets
  signal cur_pkts            : unsigned(18 downto 0); -- maximum 22-bit count of elements => maximum 19-bit count of 8-Byte packets
  signal prepad_cnt          : unsigned( 1 downto 0); -- count number of prepad rows

  -- maximum burst size is 16 packets
  constant burst_size        : unsigned( 7 downto 0) := to_unsigned(16, 8);
  -- zero
  constant zero_cols         : unsigned( 7 downto 0) := (others => '0');
  constant zero_pkts         : unsigned(18 downto 0) := (others => '0');

  -----------------------
  -- GENERAL CONSTANTS --
  -----------------------

  -- addresses
  constant MC_ADDR_STATE     : std_logic_vector( 2 downto 0)
  := "100";
  constant MC_ADDR_OUT_ADDR  : std_logic_vector( 2 downto 0) := "001";
  constant MC_ADDR_TX_ADDR   : std_logic_vector( 2 downto 0) := "010";

  -----------------------------------------------------------
  -- Return whether the module has received a command packet.
  -- params:
  --   new_pkt Pulsed signal for received packets.
  --   addr    Address of received packets.
  -----------------------------------------------------------
  function is_command_pkt (
    new_pkt : std_logic;
    addr    : std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0)
  ) return std_logic is
    begin
      return new_pkt and addr(G_ADDR_PKT_WIDTH-1);
    end;

  -----------------------------------------------------------
  -- Return whether the module has received a payload packet.
  -- params:
  --   new_pkt Pulsed signal for received packets.
  --   addr    Address of received packets.
  -----------------------------------------------------------
  function is_payload_pkt (
    new_pkt : std_logic;
    addr    : std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0)
  ) return std_logic is
    begin
      return new_pkt and not(addr(G_ADDR_PKT_WIDTH-1));
    end;

begin

  ------------------
  -- Main Process --
  ------------------
  p_main : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0' or i_por_n = '0') then
        -- active-low reset external signals
        o_write_blank_en    <= '0';
        o_drop_pkts         <= '0';
        o_addr              <= (others => '0');
        o_ren               <= '0';
        o_wen               <= '0';
        o_wdata             <= (others => '0');
        o_cmd_valid         <= '0';
        o_cmd_err           <= '0';
        o_cmd_kern          <= '0';
        o_cmd_subj          <= '0';
        o_cmd_kern_signed   <= '0';
        o_eor               <= '0';
        o_prepad_done       <= '0';
        o_payload_done      <= '0';

        -- active-low reset internal signals
        input_fsm_state     <= FSM_RESTART;
        cur_cmd_chksum      <= (others => '0');
        cur_cmd_status      <= MC_STAT_OKAY;
        new_cmd_status      <= MC_STAT_OKAY;
        cur_cmd_kern        <= '0';
        cur_cmd_subj        <= '0';
        cur_cmd_kern_signed <= '0';
        cur_cmd_err         <= '0';
        cur_cmd_cmplt       <= '0';
        exp_cols            <= (others => '0');
        cur_cols            <= (others => '0');
        cur_pkts            <= (others => '0');
        prepad_cnt          <= (others => '0');
        write_blank_ack     <= '0';
      else
        -- CDC signals
        write_blank_ack <= i_write_blank_ack;

        -- apply checksum and status changes
        if (input_fsm_state = FSM_RESTART) then
          cur_cmd_status <= (others => '0');
          cur_cmd_chksum <= (others => '0');
        else
          cur_cmd_status <= cur_cmd_status or new_cmd_status;
          if (is_command_pkt(i_rx_pkt, i_rx_addr) = '1') then
            cur_cmd_chksum <= cur_cmd_chksum xor
            i_rx_data(31 downto 0) xor i_rx_data(63 downto 32);
          else
            cur_cmd_chksum <= cur_cmd_chksum;
          end if;
        end if;

        -- calculate new state
        case (input_fsm_state) is

          when FSM_RESTART =>
            -- reset internal signals
            cur_cmd_kern      <= '0';
            cur_cmd_subj      <= '0';
            new_cmd_status    <= (others => '0');
            cur_cmd_err       <= '0';
            cur_cmd_cmplt     <= '0';
            exp_cols          <= (others => '0');
            cur_cols          <= (others => '0');
            cur_pkts          <= (others => '0');
            prepad_cnt        <= (others => '0');

            -- default interface signal
            o_wen             <= '0';
            o_write_blank_en  <= '0';
            o_drop_pkts       <= '0';
            o_ren             <= '0';
            o_cmd_valid       <= '0';
            o_cmd_err         <= '0';
            o_cmd_kern        <= '0';
            o_cmd_kern_signed <= '0';
            o_cmd_subj        <= '0';
            o_eor             <= '0';
            o_prepad_done     <= '0';
            o_payload_done    <= '0';

            input_fsm_state <= WAIT_CMD_S_KEY;

          -- waiting for the first 64b packet in the command
          when WAIT_CMD_S_KEY =>
            if (is_command_pkt(i_rx_pkt, i_rx_addr) = '1') then
              -- process S_KEY field, i_rx_data(31 downto 0)
              --   [31:0]: S_KEY
              if (i_rx_data(31 downto 0) = MC_CMD_S_KEY) then
                new_cmd_status <= (others => '0');
                cur_cmd_err    <= '0';
              else
                new_cmd_status <= MC_STAT_ERR_KEY;
                cur_cmd_err    <= '1';
              end if;

              -- process CMD fields, i_rx_data(63 downto 32)
              --   [   31]: KERN_SIGNED
              --   [   30]: LOAD_TYPE
              --   [29: 0]: OUT_ADDR
              cur_cmd_kern_signed <= i_rx_data(32+31);
              if (i_rx_data(32+30) = MC_CMD_CMD_KERN) then
                cur_cmd_kern <= '1';
                cur_cmd_subj <= '0';
              else -- i_rx_data(32+30) = MC_CMD_CMD_SUBJ
                cur_cmd_kern <= '0';
                cur_cmd_subj <= '1';
                o_wen        <= '1';
              end if;
              -- write OUT_ADDR
              o_wdata(31 downto 2) <= i_rx_data(32+29 downto 32+0);
              o_addr(2 downto 0)   <= MC_ADDR_OUT_ADDR;

              -- next state
              input_fsm_state <= WAIT_CMD_SIZE;
            else
            end if;

          -- waiting for the second 64b packet in the command
          when WAIT_CMD_SIZE =>
            if (is_command_pkt(i_rx_pkt, i_rx_addr) = '1') then
              -- process SIZE fields, i_rx_data(31 downto 0)
              --   [31:30]: Reserved
              --   [29:15]: MAT_EL
              --   [14: 4]: MAT_ROWS
              --   [ 3: 0]: MAT_COLS

              -- exp_cols only matters for subject matrix
              exp_cols <= i_rx_data(3 downto 0);
              -- left shift by 7 bits for subject then truncate 3 bits
              cur_cols <= unsigned(i_rx_data(3 downto 0) & "0000");

              if (cur_cmd_kern = '1') then
                -- size of kernel is given as a raw integer
                -- take multiples of 8-bytes (truncate 3 LSbs)
                cur_pkts <= unsigned("0000000" & i_rx_data(29 downto 18));

                -- validate size of kernel (32 elements)
                if (not(i_rx_data(29 downto 15) = "000000000100000")) then
                  new_cmd_status <= MC_STAT_ERR_SIZE;
                  cur_cmd_err    <= '1';
                end if;
              else -- cur_cmd_subj = '1'
                -- size of subject is given as a multiple of 128
                -- pad with seven zeros then truncate 3 LSbs
                cur_pkts <= unsigned(i_rx_data(29 downto 15) & "0000");
              end if;

              -- process TX_ADDR fields, i_rx_data(63 downto 32)
              o_wdata(31 downto 2) <= i_rx_data(32+29 downto 32+0);
              o_addr(2 downto 0)   <= MC_ADDR_TX_ADDR;
              o_wen                <= '1';

              -- next state
              input_fsm_state <= WAIT_CMD_TID;
            else
              -- default interface signals
              o_wen <= '0';
            end if;

          -- waiting for the third 64b packet in the command
          when WAIT_CMD_TID =>
            if (is_command_pkt(i_rx_pkt, i_rx_addr) = '1') then
              -- process TRANS_ID fields, i_rx_data(31 downto 0)

              -- next state
              input_fsm_state <= WAIT_CMD_E_KEY;
            else
            end if;

            -- clear signals from previous states
            o_wen <= '0';

          -- waiting for the fourth 64b packet in the command
          when WAIT_CMD_E_KEY =>
            if (is_command_pkt(i_rx_pkt, i_rx_addr) = '1') then
              -- process E_KEY fields, i_rx_data(31 downto 0)
              if (not(i_rx_data(31 downto 0) = MC_CMD_E_KEY)) then
                new_cmd_status <= MC_STAT_ERR_KEY;
                cur_cmd_err    <= '1';
              end if;

              -- process CHKSUM fields, i_rx_data(63 downto 32)
              -- cur_cmd_chksum not updated until next clock cycle

              -- next state
              input_fsm_state <= CHECK_CHKSUM;
            else
            end if;

          -- checking the integrity of the command checksum
          when CHECK_CHKSUM =>
            -- check the checksum (should be zeroed out after receiving all fields including the command checksum)
            if (not(cur_cmd_chksum = ((cur_cmd_chksum'range) => '0'))) then
              new_cmd_status <= MC_STAT_ERR_CKSM;
              cur_cmd_err    <= '1';

              -- next state
              input_fsm_state <= ACK_STAT_TX;
            elsif (cur_cmd_err = '1') then
              -- next state
              input_fsm_state <= ACK_STAT_TX;
            else
              -- valid state
              input_fsm_state <= PAYLOAD_RX;
              cur_cmd_cmplt   <= '1';

              -- broadcast command type
              o_cmd_kern        <= cur_cmd_kern;
              o_cmd_subj        <= cur_cmd_subj;
              o_cmd_kern_signed <= cur_cmd_kern_signed;
            end if;

          -- receiving payload data
          when PAYLOAD_RX =>
            -- update counters
            if (i_rvalid = '1') then
              -- copy loaded state to counter
              cur_pkts       <= unsigned(i_rdata(31 downto 13));
              cur_cols       <= unsigned(i_rdata(12 downto 5));
              cur_cmd_status <= i_rdata( 4 downto 0);
            elsif (is_payload_pkt(i_rx_pkt, i_rx_addr) = '1') then
              -- end of row logic
              if (cur_cols = zero_cols) then
                cur_cols <= unsigned(exp_cols & "0000");
                cur_pkts <= cur_pkts;
                o_eor    <= cur_cmd_subj;

                -- count number of pre-subject padding rows
                if (prepad_cnt = "00") then
                  prepad_cnt <= "01";
                elsif (prepad_cnt = "01") then
                  prepad_cnt <= "10";
                else
                  prepad_cnt <= prepad_cnt;
                end if;
              else
                cur_cols <= cur_cols - 1;
                cur_pkts <= cur_pkts - 1;
                o_eor    <= '0';
              end if;
            else
              -- default values
              o_eor <= '0';
            end if;

            -- write blank logic
            if (cur_cols < burst_size) then
              o_write_blank_en <= cur_cmd_subj;
            elsif (write_blank_ack = '1') then
              o_write_blank_en <= '0';
            end if;

            -- next state logic
            if (i_proc_error = '1') then
              -- processing error
              new_cmd_status  <= MC_STAT_ERR_PROC;
              cur_cmd_err     <= '1';
              input_fsm_state <= ACK_STAT_TX;
            elsif (cur_pkts = zero_pkts) then
              -- end of payload logic
              o_payload_done  <= '1';
              input_fsm_state <= WAIT_RES_TX;
            else
              -- continue receiving packets
              input_fsm_state <= PAYLOAD_RX;
            end if;

            -- propagate pre-subject padding logic
            o_prepad_done     <= prepad_cnt(1);

            -- clear signals from previous states
            o_ren             <= '0';

          -- wait for the result transmission
          when WAIT_RES_TX =>
            -- wait for output FSM signal
            if (i_res_written = '1') then
              input_fsm_state <= ACK_STAT_TX;
            end if;

            -- clear signals from previous states
            o_eor            <= '0';
            o_write_blank_en <= '0';

          -- need to write status of the command
          when ACK_STAT_TX =>
            -- save state
            o_addr                <= MC_ADDR_STATE;
            o_wdata(31 downto 13) <= std_logic_vector(cur_pkts);
            o_wdata(12 downto  5) <= std_logic_vector(cur_cols);
            o_wdata( 4 downto  0) <= cur_cmd_status or new_cmd_status;
            o_wen                 <= '1';

            -- broadcast status
            o_cmd_valid           <= not(cur_cmd_err);
            o_cmd_err             <= cur_cmd_err;

            -- transition to next state
            if (cur_cmd_err = '1') then
              -- transmitted error status, need acknowledgement of error
              input_fsm_state <= WAIT_ERR_ACK;

              -- update external interface
              o_drop_pkts     <= '1';
            else
              -- transmitted final status, ready for new command
              input_fsm_state <= FSM_RESTART;
            end if;

          -- waiting for error acknowledgement
          when WAIT_ERR_ACK =>
            --o_cmd_stat_valid <= '0';
            if (i_state_reg_pls = '1') then
              if (cur_cmd_cmplt = '1') then
                -- load in saved processing state
                o_addr          <= MC_ADDR_STATE;
                o_ren           <= '1';
                input_fsm_state <= PAYLOAD_RX;
              else
                -- restart command
                input_fsm_state <= FSM_RESTART;
              end if;
              o_drop_pkts <= '0';
            end if;

            -- clear signals from previous states
            o_wen               <= '0';

          -- unknown state
          when others =>
            -- go into processing error state
            new_cmd_status  <= MC_STAT_ERR_PROC;
            cur_cmd_err     <= '1';
            cur_cmd_cmplt   <= '0';
            input_fsm_state <= ACK_STAT_TX;

        end case;
      end if;
    end if;
  end process p_main;

end rtl;
