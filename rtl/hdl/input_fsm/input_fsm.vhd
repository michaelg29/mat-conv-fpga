
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
    i_wdata           : in  std_logic_vector(G_DATA_PKT_WIDTH-1 downto 0);
    i_waddr           : in  std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
    i_new_pkt         : in  std_logic;

    -- signals to and from AXI Receiver
    i_write_blank_ack : in  std_logic;
    o_write_blank_en  : out std_logic;
    o_drop_pkts       : out std_logic;

    -- signals to and from APB Receiver
    i_read_status     : in  std_logic;

    -- signals to and from Command Buffer
    o_cmd_data        : out std_logic_vector(31 downto 0);
    o_cmd_data_id     : out std_logic_vector( 2 downto 0);
    o_cmd_data_valid  : out std_logic;

    -- signals to and from Clusters
    o_eor             : out std_logic;

    -- global status signals
    i_res_written     : in  std_logic;
    o_cmd_kern        : out std_logic;
    o_cmd_subj        : out std_logic;
    o_cmd_valid       : out std_logic;
    o_cmd_err         : out std_logic
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
  signal cur_cmd_chksum : std_logic_vector(31 downto 0);
  signal cur_cmd_status : std_logic_vector(31 downto 0);
  signal new_cmd_status : std_logic_vector(31 downto 0);
  signal cur_cmd_kern   : std_logic;
  signal cur_cmd_subj   : std_logic;
  signal cur_cmd_err    : std_logic;
  signal complete_cmd   : std_logic;

  ----------------------
  -- PAYLOAD COUNTERS --
  ----------------------
  signal expected_cols  : std_logic_vector( 3 downto 0); -- 4 bits in the SIZE field of the command
  signal current_cols   : unsigned( 7 downto 0); -- maximum 11-bit count of columns => maximum 8-bit count of 8-Byte packets
  signal current_pkts   : unsigned(18 downto 0); -- maximum 22-bit count of elements => maximum 19-bit count of 8-Byte packets

  -- maximum burst size is 16 packets
  constant burst_size   : unsigned( 7 downto 0) := to_unsigned(16, 8);
  -- zero
  constant zero_cols    : unsigned( 7 downto 0) := (others => '0');
  constant zero_pkts    : unsigned(18 downto 0) := (others => '0');

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
        o_write_blank_en <= '0';
        o_drop_pkts      <= '0';
        o_cmd_data       <= (others => '0');
        o_cmd_data_id    <= (others => '0');
        o_cmd_data_valid <= '0';
        o_eor            <= '0';
        o_cmd_kern       <= '0';
        o_cmd_subj       <= '0';
        o_cmd_valid      <= '0';
        o_cmd_err        <= '0';

        -- active-low reset internal signals
        input_fsm_state  <= WAIT_CMD_S_KEY;
        cur_cmd_chksum   <= (others => '0');
        cur_cmd_status   <= MC_STAT_OKAY;
        new_cmd_status   <= MC_STAT_OKAY;
        cur_cmd_kern     <= '0';
        cur_cmd_subj     <= '0';
        cur_cmd_err      <= '0';
        complete_cmd     <= '0';
        expected_cols    <= (others => '0');
        current_cols     <= (others => '0');
        current_pkts     <= (others => '0');
      else
        -- apply checksum and status changes
        cur_cmd_status <= cur_cmd_status or new_cmd_status;

        if (is_command_pkt(i_new_pkt, i_waddr) = '1') then
          cur_cmd_chksum <= cur_cmd_chksum xor
          i_wdata(31 downto 0) xor i_wdata(63 downto 32);
        else
          cur_cmd_chksum <= cur_cmd_chksum;
        end if;

        -- calculate new state
        case (input_fsm_state) is

          -- waiting for the first 64b packet in the command
          when WAIT_CMD_S_KEY =>
            if (is_command_pkt(i_new_pkt, i_waddr) = '1') then
              -- process S_KEY field, i_wdata(31 downto 0)
              --   [31:0]: S_KEY
              if (i_wdata(31 downto 0) = MC_CMD_S_KEY) then
                new_cmd_status <= (others => '0');
                cur_cmd_err    <= '0';
              else
                new_cmd_status <= MC_STAT_ERR_KEY;
                cur_cmd_err    <= '1';
              end if;

              -- process CMD field, i_wdata(63 downto 32)
              --   [   31]: Reserved
              --   [   30]: LOAD_TYPE
              --   [29: 0]: OUT_ADDR
              if (i_wdata(32+30) = MC_CMD_CMD_KERN) then
                cur_cmd_kern <= '1';
                cur_cmd_subj <= '0';
              else
                cur_cmd_kern <= '0';
                cur_cmd_subj <= '1';
              end if;

              -- next state
              input_fsm_state <= WAIT_CMD_SIZE;
            else
              -- reset internal signals
              cur_cmd_kern   <= '0';
              cur_cmd_subj   <= '0';
              new_cmd_status <= (others => '0');
              cur_cmd_err    <= '0';
            end if;

            -- initial interface signals
            o_write_blank_en <= '0';
            o_drop_pkts         <= '0';
            o_cmd_data_valid <= '0';
            o_eor            <= '0';
            o_cmd_kern       <= '0';
            o_cmd_subj       <= '0';
            o_cmd_valid      <= '0';
            o_cmd_err        <= '0';

            -- initial internal signals
            complete_cmd   <= '0';
            expected_cols  <= (others => '0');
            current_cols   <= (others => '0');
            current_pkts   <= (others => '0');

          -- waiting for the second 64b packet in the command
          when WAIT_CMD_SIZE =>
            if (is_command_pkt(i_new_pkt, i_waddr) = '1') then
              -- process SIZE field, i_wdata(31 downto 0)
              --   [31:30]: Reserved
              --   [29:15]: MAT_EL
              --   [14: 4]: MAT_ROWS
              --   [ 3: 0]: MAT_COLS

              -- expected_cols only matters for subject matrix
              -- pad with seven zeros then truncate 3 LSbs
              expected_cols <= i_wdata(3 downto 0);
              if (cur_cmd_kern = '1') then
                -- size of kernel is given as a raw integer
                -- take multiples of 8-bytes (truncate 3 LSbs)
                current_pkts <= unsigned("0000000" & i_wdata(29 downto 18));

                -- validate size of kernel (32 elements)
                if (not(i_wdata(29 downto 15) = "000000000100000")) then
                  new_cmd_status <= MC_STAT_ERR_SIZE;
                  cur_cmd_err    <= '1';
                end if;
              elsif (cur_cmd_subj = '1') then
                -- size of subject is given as a multiple of 128
                -- pad with seven zeros then truncate 3 LSbs
                current_pkts <= unsigned(i_wdata(29 downto 15) & "0000");
              end if;

              -- process TX_ADDR field, i_wdata(63 downto 32)

              -- next state
              input_fsm_state <= WAIT_CMD_TID;
            else
            end if;

          -- waiting for the third 64b packet in the command
          when WAIT_CMD_TID =>
            if (is_command_pkt(i_new_pkt, i_waddr) = '1') then
              -- process TRANS_ID field, i_wdata(31 downto 0)

              -- next state
              input_fsm_state <= WAIT_CMD_E_KEY;
            else
            end if;

          -- waiting for the fourth 64b packet in the command
          when WAIT_CMD_E_KEY =>
            if (is_command_pkt(i_new_pkt, i_waddr) = '1') then
              -- process E_KEY field, i_wdata(31 downto 0)
              if (i_wdata(31 downto 0) = MC_CMD_E_KEY) then
                new_cmd_status <= (others => '0');
              else
                new_cmd_status <= MC_STAT_ERR_KEY;
                cur_cmd_err    <= '1';
              end if;

              -- process CHKSUM field, i_wdata(63 downto 32)
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
              complete_cmd    <= '1';

              -- start column counter
              -- left shift by 7 bits for subject then truncate 3 bits
              current_cols    <= unsigned(expected_cols & "0000");

              -- broadcast status
              o_cmd_kern  <= cur_cmd_kern;
              o_cmd_subj  <= cur_cmd_subj;
            end if;

            -- broadcast command type
            o_cmd_valid <= not(cur_cmd_err);
            o_cmd_err   <= cur_cmd_err;

          -- receiving payload data
          when PAYLOAD_RX =>
            if (is_payload_pkt(i_new_pkt, i_waddr) = '1') then
              -- increment counters
              current_pkts   <= current_pkts - 1;

              -- end of row logic
              if (current_cols = zero_cols) then
                current_cols <= unsigned(expected_cols & "0000");
                o_eor        <= '1';
              else
                current_cols <= current_cols - 1;
                o_eor        <= '0';
              end if;
            else
              -- default values
              o_eor <= '0';
            end if;

            -- end of payload logic
            if (current_pkts  = zero_pkts) then
              input_fsm_state <= WAIT_RES_TX;
            end if;

            -- write blank logic
            if (current_cols < burst_size) then
              o_write_blank_en <= '1';
            elsif (i_write_blank_ack = '1') then
              o_write_blank_en <= '0';
            end if;

            input_fsm_state <= WAIT_CMD_S_KEY;

          -- wait for the result transmission
          when WAIT_RES_TX =>
            -- wait for output FSM signal
            if (i_res_written = '1') then
              input_fsm_state <= ACK_STAT_TX;
            end if;

          -- need to write status of the command
          when ACK_STAT_TX =>
            -- broadcast status
            o_cmd_data       <= cur_cmd_status;
            o_cmd_data_id    <= MC_CMD_ID_STATUS;
            o_cmd_data_valid <= '1';

            -- transition to next state
            if (cur_cmd_err = '1') then
              -- transmitted error status, need acknowledgement of error
              input_fsm_state <= WAIT_ERR_ACK;

              -- update external interface
              o_drop_pkts     <= '1';
            else
              -- transmitted final status, ready for new command
              input_fsm_state <= WAIT_CMD_S_KEY;
            end if;

          -- waiting for error acknowledgement
          when WAIT_ERR_ACK =>
            o_cmd_data_valid <= '0';
            if (i_read_status = '1') then
              if (complete_cmd = '1') then
                -- TODO load in saved state
                --current_cols <= XXX;
                --current_pkts <= XXX;
                input_fsm_state <= PAYLOAD_RX;
              else
                -- restart command
                input_fsm_state <= WAIT_CMD_S_KEY;
              end if;
              o_drop_pkts <= '0';
            end if;

          -- unknown state
          when others =>
            -- go into processing error state
            new_cmd_status  <= MC_STAT_ERR_PROC;
            cur_cmd_err     <= '1';
            complete_cmd    <= '0';
            input_fsm_state <= ACK_STAT_TX;

        end case;
      end if;
    end if;
  end process p_main;

end rtl;
