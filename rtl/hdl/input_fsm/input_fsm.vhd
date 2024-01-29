
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

    -- signals to and from Input FIFO
    i_wdata           : in  std_logic_vector(G_DATA_PKT_WIDTH-1 downto 0);
    i_waddr           : in  std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
    i_new_pkt         : in  std_logic;

    -- signals to and from AXI Receiver
    i_write_blank_ack : in  std_logic;
    o_write_blank_en  : out std_logic;
    o_ignore          : out std_logic;

    -- signals to and from APB Receiver
    i_read_status     : in  std_logic;

    -- signals to and from Command Buffer
    o_cmd_data        : out std_logic_vector(31 downto 0);
    o_cmd_data_id     : out std_logic_vector( 2 downto 0);
    o_cmd_data_valid  : out std_logic;

    -- signals to and from Clusters
    o_eor             : out std_logic;

    -- global output status signals
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

  -- state definition
  type INPUT_FSM_STATE_T is (
    WAIT_CMD_SKEY,
    WAIT_CMD_SIZE,
    WAIT_CMD_TID,
    WAIT_CMD_EKEY,
    WAIT_ERR_ACK,
    PAYLOAD_RX,
    WAIT_RES_TX,
    ACK_STAT_TX,
    ACK_CHKSUM_TX
  );
  signal input_fsm_state : INPUT_FSM_STATE_T;

  -- command signals
  signal cur_cmd_chksum : std_logic_vector(31 downto 0);
  signal cur_cmd_status : std_logic_vector(31 downto 0);
  signal new_cmd_chksum : std_logic_vector(31 downto 0);
  signal new_cmd_status : std_logic_vector(31 downto 0);
  signal cur_cmd_kern   : std_logic;
  signal cur_cmd_subj   : std_logic;

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
      if (i_rst_n = '0') then
        -- active-low reset external signals
        o_write_blank_en <= '0';
        o_ignore         <= '0';
        o_cmd_data       <= (others => '0');
        o_cmd_data_id    <= (others => '0');
        o_cmd_data_valid <= '0';
        o_eor            <= '0';
        o_cmd_kern       <= '0';
        o_cmd_subj       <= '0';
        o_cmd_valid      <= '0';
        o_cmd_err        <= '0';

        -- active-low reset internal signals
        input_fsm_state  <= WAIT_CMD_SKEY;
        cur_cmd_chksum   <= (others => '0');
        cur_cmd_status   <= MC_STAT_OKAY;
        new_cmd_chksum   <= (others => '0');
        new_cmd_status   <= MC_STAT_OKAY;
        cur_cmd_kern     <= '0';
        cur_cmd_subj     <= '0';
      else
        -- apply checksum and status changes
        cur_cmd_chksum <= cur_cmd_chksum xor new_cmd_chksum;
        cur_cmd_status <= cur_cmd_status or  new_cmd_status;

        if (is_command_pkt(i_new_pkt, i_waddr) = '1') then
          new_cmd_chksum <= i_wdata(31 downto 0) xor i_wdata(63 downto 32);
        else
          new_cmd_chksum <= (others => '0');
        end if;

        -- calculate new state
        case (input_fsm_state) is

          when WAIT_CMD_SKEY =>
            if (is_command_pkt(i_new_pkt, i_waddr) = '1') then
              -- validate SKEY field
              if (i_wdata(31 downto 0) = MC_CMD_SKEY) then
                new_cmd_status <= (others => '0');
              else
                new_cmd_status <= MC_STAT_ERR_KEY;
              end if;

              -- validate CMD field
              if (i_wdata(62) = MC_CMD_CMD_KERN) then
                cur_cmd_kern <= '1';
                cur_cmd_subj <= '0';
              else
                cur_cmd_kern <= '0';
                cur_cmd_subj <= '1';
              end if;

              -- next state
              input_fsm_state <= WAIT_CMD_SIZE;
            end if;

          when WAIT_CMD_SIZE =>
            input_fsm_state <= WAIT_CMD_SKEY;

          when WAIT_CMD_TID =>
            input_fsm_state <= WAIT_CMD_SKEY;

          when WAIT_CMD_EKEY =>
            input_fsm_state <= WAIT_CMD_SKEY;

          when WAIT_ERR_ACK =>
            input_fsm_state <= WAIT_CMD_SKEY;

          when WAIT_RES_TX =>
            input_fsm_state <= WAIT_CMD_SKEY;
            
          when ACK_STAT_TX =>
            input_fsm_state <= WAIT_CMD_SKEY;
            
          when ACK_CHKSUM_TX =>
            input_fsm_state <= WAIT_CMD_SKEY;

          when others =>
            input_fsm_state <= WAIT_CMD_SKEY;

        end case;
      end if;
    end if;
  end process p_main;

end rtl;
