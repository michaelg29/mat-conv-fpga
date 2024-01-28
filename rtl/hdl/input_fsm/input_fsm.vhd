
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------
-- Input FSM entity --
----------------------
entity input_fsm is
  generic (
    -- packet widths
    G_DATA_PKT_WIDTH   : integer := 64; -- width of an AXI data packet
    G_ADDR_PKT_WIDTH   : integer := 8;  -- required relative address size
    
    -- constants
    G_MC_CMD_SKEY      : std_logic_vector(31 downto 0) := x"CAFECAFE";
    G_MC_CMD_EKEY      : std_logic_vector(31 downto 0) := x"DEADBEEF";
    
    -- error codes
    G_MC_STAT_OKAY     : std_logic_vector(31 downto 0) := x"00000000";
    G_MC_STAT_ERR_PROC : std_logic_vector(31 downto 0) := x"00000001";
    G_MC_STAT_ERR_KEY  : std_logic_vector(31 downto 0) := x"00000002";
    G_MC_STAT_ERR_SIZE : std_logic_vector(31 downto 0) := x"00000004";
    G_MC_STAT_ERR_CKSM : std_logic_vector(31 downto 0) := x"00000008"
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
    WAIT_RES_TX
  );
  signal input_fsm_state : INPUT_FSM_STATE_T;

begin

  p_main : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0') then
        -- active-low reset signals
        input_fsm_state <= WAIT_CMD_SKEY;
      else
        
      end if;
    end if;
  end process p_main;

end rtl;
