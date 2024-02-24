
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library mem_wrapper_library;
use mem_wrapper_library.all;

-------------------
-- Register file --
-------------------
entity register_file is
  generic (
    -- latency of a read in clock cycles
    READ_LATENCY : integer
  );
  port (
    -- clock and reset
    i_aclk       : in  std_logic;
    i_macclk     : in  std_logic;
    i_pclk       : in  std_logic;
    i_rst_n      : in  std_logic;

    -- port A reader 0 - Input FSM
    i_ar0_ren    : in  std_logic;
    o_ar0_rdata  : out std_logic_vector(31 downto 0);
    o_ar0_rvalid : out std_logic;

    -- port A reader 1 - Output FSM
    i_ar1_ren    : in  std_logic;
    i_ar1_addr   : in  std_logic;
    o_ar1_rdata  : out std_logic_vector(31 downto 0);
    o_ar1_rvalid : out std_logic;

    -- port B reader - APB Rx
    i_br_ren     : in  std_logic;
    o_br_rdata   : out std_logic_vector(31 downto 0);
    o_br_rvalid  : out std_logic;

    -- port C writer 0 - Input FSM
    i_cw0_addr   : in  std_logic_vector( 1 downto 0);
    i_cw0_wen    : in  std_logic;
    i_cw0_wdata  : in  std_logic_vector(31 downto 0);

    -- port C writer 1 - AXI Tx
    i_cw1_wen    : in  std_logic;
    i_cw1_wdata  : in  std_logic_vector(31 downto 0)
  );
end register_file;

architecture rtl of register_file is

  -- internal memory block
  component RTG4uSRAM_0 is
    generic(
      -- static signals on port A
      A_WIDTH         : std_logic;
      A_DOUT_BYPASS   : std_logic;
      A_ADDR_BYPASS   : std_logic;

      -- static signals on port B
      B_WIDTH         : std_logic;
      B_DOUT_BYPASS   : std_logic;
      B_ADDR_BYPASS   : std_logic;

      -- static signals on port C
      C_WIDTH         : std_logic;

      -- static common signals
      ECC_EN          : std_logic := '1';
      ECC_DOUT_BYPASS : std_logic := '0';
      DELEN           : std_logic;
      SECURITY        : std_logic
    );
    port(
      -- port A (reader)
      A_ADDR          : in  std_logic_vector( 6 downto 0);
      A_BLK           : in  std_logic_vector( 1 downto 0);
      A_DOUT          : out std_logic_vector(17 downto 0);
      A_DOUT_EN       : in  std_logic;
      A_DOUT_SRST_N   : in  std_logic;
      A_CLK           : in  std_logic;
      A_ADDR_EN       : in  std_logic;
      A_SB_CORRECT    : out std_logic;
      A_DB_DETECT     : out std_logic;

      -- port B (reader)
      B_ADDR          : in  std_logic_vector( 6 downto 0);
      B_BLK           : in  std_logic_vector( 1 downto 0);
      B_DOUT          : out std_logic_vector(17 downto 0);
      B_DOUT_EN       : in  std_logic;
      B_DOUT_SRST_N   : in  std_logic;
      B_CLK           : in  std_logic;
      B_ADDR_EN       : in  std_logic;
      B_SB_CORRECT    : out std_logic;
      B_DB_DETECT     : out std_logic;

      -- port C (writer)
      C_ADDR          : in  std_logic_vector( 6 downto 0);
      C_CLK           : in  std_logic;
      C_DIN           : in  std_logic_vector(17 downto 0);
      C_WEN           : in  std_logic;
      C_BLK           : in  std_logic_vector( 1 downto 0);

      -- common signals
      ARST_N          : in  std_logic;
      BUSY            : out std_logic
    );
  end component;

  -- signals to/from memory block
  constant B_ADDR : std_logic_vector( 6 downto 0) := "0000000";
  signal B_BLK    : std_logic_vector( 1 downto 0);
  signal B_DOUT   : std_logic_vector(35 downto 0);

  -- state signals for requests
  signal A0_RSTR : std_logic_vector(READ_LATENCY downto 0);
  signal A1_RSTR : std_logic_vector(READ_LATENCY downto 0);
  signal B_RSTR  : std_logic_vector(READ_LATENCY downto 0);

begin

  -------------------------
  -- Adjacent processing --
  -------------------------

  -- arbitrate reads from the Input FSM and Output FSM
  p_port_a_read : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0') then

      else

      end if;
    end if;
  end process;

  -- process reads from the APB Rx
  p_port_b_read : process(i_pclk)
  begin
    if (i_pclk'event and i_pclk = '1') then
      if (i_rst_n = '0') then
        B_RSTR      <= (others => '0');
        o_br_rvalid <= '0';
        o_br_rdata  <= (others => '0');
      else
        -- shift read string to represent one cycle passing in a read
        B_RSTR(READ_LATENCY-1 downto 0) <= B_RSTR(READ_LATENCY downto 1);

        -- start counter for new read
        B_RSTR(READ_LATENCY) <= i_br_ren;

        -- process completed read
        o_br_rvalid <= B_RSTR(0);
        o_br_rdata  <= B_DOUT(33 downto 18) & B_DOUT(15 downto 0);
      end if;
    end if;
  end process;

  -- arbitrate writes from the Input FSM and AXI Tx
  p_port_c_write : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0') then

      else

      end if;
    end if;
  end process;

  ----------------------------
  -- Internal memory blocks --
  ----------------------------

  -- signal concatenations


  -- bits [15:0]
  REG_FILE_0 : RTG4uSRAM_0
    generic map (
      -- static signals on port A
      A_WIDTH         => ( '1' ),
      A_DOUT_BYPASS   => ( '0' ),
      A_ADDR_BYPASS   => ( '0' ),

      -- static signals on port B
      B_WIDTH         => ( '1' ),
      B_DOUT_BYPASS   => ( '0' ),
      B_ADDR_BYPASS   => ( '0' ),

      -- static signals on port C
      C_WIDTH         => ( '1' ),

      -- static common signals
      ECC_EN          => ( '1' ),
      ECC_DOUT_BYPASS => ( '0' ),
      DELEN           => ( '1' ),
      SECURITY        => ( '0' )
    )
    port map (
      -- port A (reader) - Input FSM/Output FSM
      A_ADDR        => (others => '0'),
      A_BLK         => (others => '0'),
      A_DOUT        => open,
      A_DOUT_EN     => '0',
      A_DOUT_SRST_N => '0',
      A_CLK         => '0',
      A_ADDR_EN     => '0',
      A_SB_CORRECT  => open,
      A_DB_DETECT   => open,

      -- port B (reader) - APB Rx
      B_ADDR        => B_ADDR,
      B_BLK         => B_BLK,
      B_DOUT        => B_DOUT(17 downto 0),
      B_DOUT_EN     => '0',
      B_DOUT_SRST_N => '0',
      B_CLK         => i_aclk,
      B_ADDR_EN     => '0',
      B_SB_CORRECT  => open,
      B_DB_DETECT   => open,

      -- port C (writer) - Input FSM/AXI Tx
      C_ADDR        => (others => '0'),
      C_CLK         => '0',
      C_DIN         => (others => '0'),
      C_WEN         => '0',
      C_BLK         => (others => '0'),

      -- common signals
      ARST_N        => i_rst_n,
      BUSY          => open
    );

  -- bits [31:16]
  REG_FILE_1 : RTG4uSRAM_0
    generic map (
      -- static signals on port A
      A_WIDTH         => ( '1' ),
      A_DOUT_BYPASS   => ( '0' ),
      A_ADDR_BYPASS   => ( '0' ),

      -- static signals on port B
      B_WIDTH         => ( '1' ),
      B_DOUT_BYPASS   => ( '0' ),
      B_ADDR_BYPASS   => ( '0' ),

      -- static signals on port C
      C_WIDTH         => ( '1' ),

      -- static common signals
      ECC_EN          => ( '1' ),
      ECC_DOUT_BYPASS => ( '0' ),
      DELEN           => ( '1' ),
      SECURITY        => ( '0' )
    )
    port map (
      -- port A (reader) - Input FSM/Output FSM
      A_ADDR        => (others => '0'),
      A_BLK         => (others => '0'),
      A_DOUT        => open,
      A_DOUT_EN     => '0',
      A_DOUT_SRST_N => '0',
      A_CLK         => '0',
      A_ADDR_EN     => '0',
      A_SB_CORRECT  => open,
      A_DB_DETECT   => open,

      -- port B (reader) - APB Rx
      B_ADDR        => B_ADDR,
      B_BLK         => B_BLK,
      B_DOUT        => B_DOUT(35 downto 18),
      B_DOUT_EN     => '0',
      B_DOUT_SRST_N => '0',
      B_CLK         => i_aclk,
      B_ADDR_EN     => '0',
      B_SB_CORRECT  => open,
      B_DB_DETECT   => open,

      -- port C (writer) - Input FSM/AXI Tx
      C_ADDR        => (others => '0'),
      C_CLK         => '0',
      C_DIN         => (others => '0'),
      C_WEN         => '0',
      C_BLK         => (others => '0'),

      -- common signals
      ARST_N        => i_rst_n,
      BUSY          => open
    );

end rtl;
