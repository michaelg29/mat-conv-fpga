
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

--------------------------------------------------------------
-- Wrapper for dual-port bi-directional 1k*18 lsram_1024x18 --
--------------------------------------------------------------
entity lsram_1024x18 is
  generic(
    -- static signals on port A
    A_WIDTH         : std_logic_vector(1 downto 0);
    A_WMODE         : std_logic_vector(1 downto 0);
    A_DOUT_BYPASS   : std_logic;

    -- static signals on port B
    B_WIDTH         : std_logic_vector(1 downto 0);
    B_WMODE         : std_logic_vector(1 downto 0);
    B_DOUT_BYPASS   : std_logic;

    -- static common signals
    ECC_EN          : std_logic := '1';
    ECC_DOUT_BYPASS : std_logic := '0';
    DELEN           : std_logic;
    SECURITY        : std_logic
  );
  port(
    -- port A
    A_ADDR          : in  std_logic_vector(10 downto 0);
    A_BLK           : in  std_logic_vector( 2 downto 0);
    A_CLK           : in  std_logic;
    A_DIN           : in  std_logic_vector(17 downto 0);
    A_DOUT          : out std_logic_vector(17 downto 0);
    A_WEN           : in  std_logic_vector( 1 downto 0);
    A_REN           : in  std_logic;
    A_DOUT_EN       : in  std_logic;
    A_DOUT_SRST_N   : in  std_logic;
    A_SB_CORRECT    : out std_logic;
    A_DB_DETECT     : out std_logic;

    -- port B
    B_ADDR          : in  std_logic_vector(10 downto 0);
    B_BLK           : in  std_logic_vector( 2 downto 0);
    B_CLK           : in  std_logic;
    B_DIN           : in  std_logic_vector(17 downto 0);
    B_DOUT          : out std_logic_vector(17 downto 0);
    B_WEN           : in  std_logic_vector( 1 downto 0);
    B_REN           : in  std_logic;
    B_DOUT_EN       : in  std_logic;
    B_DOUT_SRST_N   : in  std_logic;
    B_SB_CORRECT    : out std_logic;
    B_DB_DETECT     : out std_logic;

    -- common signals
    ARST_N          : in  std_logic;
    BUSY            : out std_logic
  );
end lsram_1024x18;

architecture rtl of lsram_1024x18 is

  -- Defined in altera_mf_components.vhd
  component altsyncram
    generic (
      operation_mode                 : string := "BIDIR_DUAL_PORT";
      -- port a parameters
      width_a                        : integer := 1;
      widthad_a                      : integer := 1;
      numwords_a                     : integer := 0;
      -- registering parameters
      -- port a read parameters
      outdata_reg_a                  : string := "UNREGISTERED";
      -- clearing parameters
      address_aclr_a                 : string := "NONE";
      outdata_aclr_a                 : string := "NONE";
      -- clearing parameters
      -- port a write parameters
      indata_aclr_a                  : string := "NONE";
      wrcontrol_aclr_a               : string := "NONE";
      -- clear for the byte enable port reigsters which are clocked by clk0
      byteena_aclr_a                 : string := "NONE";
      -- width of the byte enable ports. if it is used, must be WIDTH_WRITE_A/8 or /9
      width_byteena_a                : integer := 1;
      -- port b parameters
      width_b                        : integer := 18;
      widthad_b                      : integer := 1;
      numwords_b                     : integer := 0;
      -- registering parameters
      -- port b read parameters
      rdcontrol_reg_b                : string := "CLOCK1";
      address_reg_b                  : string := "CLOCK1";
      outdata_reg_b                  : string := "UNREGISTERED";
      -- clearing parameters
      outdata_aclr_b                 : string := "NONE";
      rdcontrol_aclr_b               : string := "NONE";
      -- registering parameters
      -- port b write parameters
      indata_reg_b                   : string := "CLOCK1";
      wrcontrol_wraddress_reg_b      : string := "CLOCK1";
      -- registering parameter for the byte enable reister for port b
      byteena_reg_b                  : string := "CLOCK1";
      -- clearing parameters
      indata_aclr_b                  : string := "NONE";
      wrcontrol_aclr_b               : string := "NONE";
      address_aclr_b                 : string := "NONE";
      -- clear parameter for byte enable port register
      byteena_aclr_b                 : string := "NONE";
      -- StratixII only : to bypass clock enable or using clock enable
      clock_enable_input_a           : string := "NORMAL";
      clock_enable_output_a          : string := "NORMAL";
      clock_enable_input_b           : string := "NORMAL";
      clock_enable_output_b          : string := "NORMAL";
      -- width of the byte enable ports. if it is used, must be WIDTH_WRITE_A/8 or /9
      width_byteena_b                : integer := 1;
      -- clock enable setting for the core
      clock_enable_core_a            : string := "USE_INPUT_CLKEN";
      clock_enable_core_b            : string := "USE_INPUT_CLKEN";
      -- read-during-write-same-port setting
      read_during_write_mode_port_a  : string := "NEW_DATA_NO_NBE_READ";
      read_during_write_mode_port_b  : string := "NEW_DATA_NO_NBE_READ";
      -- ECC status ports setting
      enable_ecc                     : string := "FALSE";
      ecc_pipeline_stage_enabled	   : string := "FALSE";

      width_eccstatus                : integer := 3;
      -- global parameters
      -- width of a byte for byte enables
      byte_size                      : integer := 0;
      read_during_write_mode_mixed_ports: string := "DONT_CARE";
      -- ram block type choices are "AUTO", "M512", "M4K" and "MEGARAM"
      ram_block_type                 : string := "AUTO";
      -- determine whether LE support is turned on or off for altsyncram
      implement_in_les               : string := "OFF";
      -- determine whether RAM would be power up to uninitialized or not
      power_up_uninitialized         : string := "FALSE";

      sim_show_memory_data_in_port_b_layout :  string  := "OFF";

      -- general operation parameters
      init_file                      : string := "UNUSED";
      init_file_layout               : string := "UNUSED";
      maximum_depth                  : integer := 0;
      intended_device_family         : string := "Cyclone";
      lpm_hint                       : string := "UNUSED";
      lpm_type                       : string := "altsyncram"
    );
    port (
      wren_a    : in std_logic := '0';
      wren_b    : in std_logic := '0';
      rden_a    : in std_logic := '1';
      rden_b    : in std_logic := '1';
      data_a    : in std_logic_vector(width_a - 1 downto 0):= (others => '1');
      data_b    : in std_logic_vector(width_b - 1 downto 0):= (others => '1');
      address_a : in std_logic_vector(widthad_a - 1 downto 0);
      address_b : in std_logic_vector(widthad_b - 1 downto 0) := (others => '1');

      clock0    : in std_logic := '1';
      clock1    : in std_logic := 'Z';
      clocken0  : in std_logic := '1';
      clocken1  : in std_logic := '1';
      clocken2  : in std_logic := '1';
      clocken3  : in std_logic := '1';
      aclr0     : in std_logic := '0';
      aclr1     : in std_logic := '0';
      byteena_a : in std_logic_vector( (width_byteena_a - 1) downto 0) := (others => '1');
      byteena_b : in std_logic_vector( (width_byteena_b - 1) downto 0) := (others => 'Z');

      addressstall_a : in std_logic := '0';
      addressstall_b : in std_logic := '0';

      q_a            : out std_logic_vector(width_a - 1 downto 0);
      q_b            : out std_logic_vector(width_b - 1 downto 0);

      eccstatus      : out std_logic_vector(width_eccstatus-1 downto 0) := (others => '0')
    );
  end component;

  signal clr       : std_logic;
  signal eccstatus : std_logic_vector(1 downto 0);

begin

  -- invert active-low reset signal for active-high clear signal
  clr <= not(ARST_N);

  -- output ECC signals
  A_SB_CORRECT <= eccstatus(0);
  B_SB_CORRECT <= eccstatus(0);
  A_DB_DETECT  <= eccstatus(1);
  B_DB_DETECT  <= eccstatus(1);

  lsram_0: altsyncram
    generic map (
      operation_mode                 => ( "BIDIR_DUAL_PORT" ),
      -- port a parameters
      width_a                        => ( 18 ),
      widthad_a                      => ( 11 ),
      numwords_a                     => ( 1024 ),
      -- registering parameters
      -- port a read parameters
      outdata_reg_a                  => ( "CLOCK0" ),
      -- clearing parameters
      address_aclr_a                 => ( "NONE" ),
      outdata_aclr_a                 => ( "NONE" ),
      -- clearing parameters
      -- port a write parameters
      indata_aclr_a                  => ( "NONE" ),
      wrcontrol_aclr_a               => ( "NONE" ),
      -- clear for the byte enable port reigsters which are clocked by clk0
      byteena_aclr_a                 => ( "NONE" ),
      -- width of the byte enable ports. if it is used, must be WIDTH_WRITE_A/8 or /9
      width_byteena_a                => ( 2 ),
      -- port b parameters
      width_b                        => ( 18 ),
      widthad_b                      => ( 11 ),
      numwords_b                     => ( 1024 ),
      -- registering parameters
      -- port b read parameters
      rdcontrol_reg_b                => ( "CLOCK1" ),
      address_reg_b                  => ( "CLOCK1" ),
      outdata_reg_b                  => ( "UNREGISTERED" ),
      -- clearing parameters
      outdata_aclr_b                 => ( "NONE" ),
      rdcontrol_aclr_b               => ( "NONE" ),
      -- registering parameters
      -- port b write parameters
      indata_reg_b                   => ( "CLOCK1" ),
      wrcontrol_wraddress_reg_b      => ( "CLOCK1" ),
      -- registering parameter for the byte enable reister for port b
      byteena_reg_b                  => ( "CLOCK1" ),
      -- clearing parameters
      indata_aclr_b                  => ( "NONE" ),
      wrcontrol_aclr_b               => ( "NONE" ),
      address_aclr_b                 => ( "NONE" ),
      -- clear parameter for byte enable port register
      byteena_aclr_b                 => ( "NONE" ),
      -- width of the byte enable ports. if it is used, must be WIDTH_WRITE_A/8 or /9
      width_byteena_b                => ( 2 ),
      -- clock enable setting for the core
      clock_enable_core_a            => ( "USE_INPUT_CLKEN" ),
      clock_enable_core_b            => ( "USE_INPUT_CLKEN" ),
      -- read-during-write-same-port setting
      read_during_write_mode_port_a  => ( "NEW_DATA_NO_NBE_READ" ),
      read_during_write_mode_port_b  => ( "NEW_DATA_NO_NBE_READ" ),
      -- ECC status ports setting
      enable_ecc                     => ( "TRUE" ),
      ecc_pipeline_stage_enabled	   => ( "TRUE" ),

      width_eccstatus                => ( 2 ),
      -- global parameters
      -- width of a byte for byte enables
      byte_size                      => ( 0 ),
      read_during_write_mode_mixed_ports => ( "DONT_CARE" ),
      -- ram block type choices are "AUTO", "M512", "M4K" and "MEGARAM"
      ram_block_type                 => ( "AUTO" ),
      -- determine whether LE support is turned on or off for altsyncram
      implement_in_les               => ( "OFF" ),
      -- determine whether RAM would be power up to uninitialized or not
      power_up_uninitialized         => ( "FALSE" ),

      sim_show_memory_data_in_port_b_layout => ( "OFF" ),

      -- general operation parameters
      init_file                      => ( "UNUSED" ),
      init_file_layout               => ( "UNUSED" ),
      maximum_depth                  => ( 0 ),
      intended_device_family         => ( "Cyclone" ),
      lpm_hint                       => ( "UNUSED" ),
      lpm_type                       => ( "altsyncram" )
    )
    port map (
      wren_a    => A_WEN(0),
      wren_b    => B_WEN(0),
      rden_a    => A_REN,
      rden_b    => B_REN,
      data_a    => A_DIN,
      data_b    => B_DIN,
      address_a => A_ADDR,
      address_b => B_ADDR,

      clock0    => A_CLK,
      clock1    => B_CLK,
      clocken0  => '1',
      clocken1  => '1',
      clocken2  => '0',
      clocken3  => '0',
      aclr0     => clr,
      aclr1     => clr,
      byteena_a => A_WEN,
      byteena_b => B_WEN,

      addressstall_a => '0',
      addressstall_b => '0',

      q_a            => A_DOUT,
      q_b            => B_DOUT,

      eccstatus      => eccstatus
    );

end rtl;
