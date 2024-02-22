
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity fifo_64x512 is
  generic (
    AEVAL        : integer range 3 to 510 := 4;
    AFVAL        : integer range 3 to 510 := 500
  );
  port(
    -- Inputs
    CLK        : in  std_logic;
    RCLK       : in  std_logic;
    WCLK       : in  std_logic;
    DATA       : in  std_logic_vector(63 downto 0);
    RE         : in  std_logic;
    RESET_N    : in  std_logic;
    WE         : in  std_logic;
    -- Outputs
    AEMPTY     : out std_logic;
    AFULL      : out std_logic;
    DB_DETECT  : out std_logic;
    EMPTY      : out std_logic;
    FULL       : out std_logic;
    OVERFLOW   : out std_logic;
    Q          : out std_logic_vector(63 downto 0);
    RDCNT      : out std_logic_vector(9 downto 0);
    SB_CORRECT : out std_logic;
    UNDERFLOW  : out std_logic
  );
end fifo_64x512;
----------------------------------------------------------------------
-- fifo_64x512 architecture body
----------------------------------------------------------------------
architecture RTL of fifo_64x512 is
----------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------
--
component dcfifo
  generic (
    lpm_width               : natural;
    lpm_widthu              : natural;
    lpm_numwords            : natural;
    lpm_showahead           : string := "OFF";
    lpm_hint                : string := "USE_EAB=ON";
    overflow_checking       : string := "ON";
    underflow_checking      : string := "ON";
    delay_rdusedw           : natural := 1;
    delay_wrusedw           : natural := 1;
    rdsync_delaypipe        : natural := 0;
    wrsync_delaypipe        : natural := 0;
    use_eab                 : string := "ON";
    add_ram_output_register : string := "OFF";
    add_width               : natural := 1;
    clocks_are_synchronized : string := "FALSE";
    ram_block_type          : string := "AUTO";
    add_usedw_msb_bit       : string := "OFF";
    read_aclr_synch         : string := "OFF";
    write_aclr_synch        : string := "OFF";
    lpm_type                : string := "dcfifo";
    enable_ecc              : string := "false";
    intended_device_family  : string := "CYCLONE"
  );
  port (
    data    : in std_logic_vector(lpm_width-1 downto 0);
    rdclk   : in std_logic;
    wrclk   : in std_logic;
    wrreq   : in std_logic;
    rdreq   : in std_logic;
    aclr    : in std_logic := '0';
    rdfull  : out std_logic;
    wrfull  : out std_logic;
    wrempty : out std_logic;
    rdempty : out std_logic;
    eccstatus : out std_logic_vector(1 downto 0);
    q       : out std_logic_vector(lpm_width-1 downto 0);
    rdusedw : out std_logic_vector(lpm_widthu-1 downto 0);
    wrusedw : out std_logic_vector(lpm_widthu-1 downto 0)
  );
end component;

----------------------------------------------------------------------
-- Signal declarations
----------------------------------------------------------------------
signal AEMPTY_net_0     : std_logic;
signal AFULL_net_0      : std_logic;
signal DB_DETECT_net_0  : std_logic;
signal RDEMPTY_net_0    : std_logic;
signal WRFULL_net_0     : std_logic;
signal OVERFLOW_net_0   : std_logic;
signal Q_net_0          : std_logic_vector(63 downto 0);
signal RDCNT_net_0      : std_logic_vector(9 downto 0);
signal WRCNT_net_0      : std_logic_vector(9 downto 0);
signal SB_CORRECT_net_0 : std_logic;
signal UNDERFLOW_net_0  : std_logic;
signal RDEMPTY_net_1    : std_logic;
signal WRFULL_net_1     : std_logic;
signal AFULL_net_1      : std_logic;
signal AEMPTY_net_1     : std_logic;
signal OVERFLOW_net_1   : std_logic;
signal UNDERFLOW_net_1  : std_logic;
signal SB_CORRECT_net_1 : std_logic;
signal DB_DETECT_net_1  : std_logic;
signal Q_net_1          : std_logic_vector(63 downto 0);
signal RDCNT_net_1      : std_logic_vector(9 downto 0);
signal WRCNT_net_1      : std_logic_vector(9 downto 0);
----------------------------------------------------------------------
-- TiedOff Signals
----------------------------------------------------------------------
signal GND_net          : std_logic;
signal MEMRD_const_net_0: std_logic_vector(63 downto 0);

begin
----------------------------------------------------------------------
-- Constant assignments
----------------------------------------------------------------------
  GND_net           <= '0';
  MEMRD_const_net_0 <= B"0000000000000000000000000000000000000000000000000000000000000000";

----------------------------------------------------------------------
-- Top level output port assignments
----------------------------------------------------------------------
  WRFULL_net_1      <= WRFULL_net_0;
  FULL              <= WRFULL_net_1;
  RDEMPTY_net_1     <= RDEMPTY_net_0;
  EMPTY             <= RDEMPTY_net_1;
  AFULL_net_1       <= AFULL_net_0;
  AFULL             <= AFULL_net_1;
  AEMPTY_net_1      <= AEMPTY_net_0;
  AEMPTY            <= AEMPTY_net_1;
  OVERFLOW_net_1    <= OVERFLOW_net_0;
  OVERFLOW          <= OVERFLOW_net_1;
  UNDERFLOW_net_1   <= UNDERFLOW_net_0;
  UNDERFLOW         <= UNDERFLOW_net_1;
  SB_CORRECT_net_1  <= SB_CORRECT_net_0;
  SB_CORRECT        <= SB_CORRECT_net_1;
  DB_DETECT_net_1   <= DB_DETECT_net_0;
  DB_DETECT         <= DB_DETECT_net_1;
  Q_net_1           <= Q_net_0;
  Q(63 downto 0)    <= Q_net_1;
  RDCNT_net_1       <= RDCNT_net_0;
  RDCNT(9 downto 0) <= RDCNT_net_1;

----------------------------------------------------------------------
-- Almost empty and almost full process
----------------------------------------------------------------------
  p_aempty : process(RCLK, RESET_N)
  begin
    if (RESET_N = '0') then
      AEMPTY_net_0 <= '0'; 
    elsif (RCLK'event and RCLK = '1') then
      if (to_integer(unsigned(RDCNT_net_0)) <= AEVAL) then
        AEMPTY_net_0 <= '1';
      else
        AEMPTY_net_0 <= '0';
      end if;
    end if;
  end process p_aempty;
  
  p_afull : process(WCLK, RESET_N)
  begin
    if (RESET_N = '0') then
      AFULL_net_0 <= '0'; 
    elsif (WCLK'event and WCLK = '1') then
      if (to_integer(unsigned(WRCNT_net_0)) >= AFVAL) then
        AFULL_net_0 <= '1';
      else
        AFULL_net_0 <= '0';
      end if;
    end if;
  end process p_afull;

----------------------------------------------------------------------
-- Component instances
----------------------------------------------------------------------

dcfifo64x512_0 : dcfifo
  generic map (
    lpm_width               => ( 64 ),
    lpm_widthu              => ( 10 ),
    lpm_numwords            => ( 512 ),
    lpm_showahead           => ( "OFF" ),
    lpm_hint                => ( "USE_EAB=ON" ),
    lpm_type                => ( "DCFIFO" ),
    overflow_checking       => ( "ON" ),
    underflow_checking      => ( "ON" ),
    enable_ecc              => ( "OFF" ),
    delay_rdusedw           => ( 1 ),
    delay_wrusedw           => ( 1 ),
    add_usedw_msb_bit       => ( "OFF" ),
    rdsync_delaypipe        => ( 3 ),
    wrsync_delaypipe        => ( 3 ),
    use_eab                 => ( "ON" ),
    write_aclr_synch        => ( "OFF" ),
    read_aclr_synch         => ( "OFF" ),
    clocks_are_synchronized => ( "FALSE" ),
    ram_block_type          => ( "AUTO" ),
    add_ram_output_register => ( "OFF" ),
    add_width               => ( 1 )
  )
  port map (
    wrclk        => WCLK,
    rdclk        => RCLK,
    data         => DATA,
    wrreq        => WE,
    rdreq        => RE,
    aclr         => RESET_N,
    q            => Q_net_0,
    wrfull       => WRFULL_net_0,
    rdfull       => open,
    wrempty      => open,
    rdempty      => RDEMPTY_net_0,
    wrusedw      => WRCNT_net_0,
    rdusedw      => RDCNT_net_0,
    eccstatus    => open
  );

end RTL;
