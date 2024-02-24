
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library mem_wrapper_library;
use mem_wrapper_library.all;

------------------------
-- Acknowledge buffer --
------------------------
entity acknowledge_buffer is
  generic (
    -- latency of a read in clock cycles
    READ_LATENCY : integer
  );
  port (
    -- clock and reset
    i_aclk       : in  std_logic;
    i_macclk     : in  std_logic;
    i_rst_n      : in  std_logic;

    -- port A reader - Output FSM
    i_ar_addr    : in  std_logic_vector( 2 downto 0);
    i_ar_ren     : in  std_logic;
    o_ar_rdata   : out std_logic_vector(31 downto 0);
    o_ar_rvalid  : out std_logic;
    
    -- port C writer 0 - AXI Rx
    i_cw0_addr   : in  std_logic_vector( 3 downto 0);
    i_cw0_wen    : in  std_logic;
    i_cw0_wdata  : in  std_logic_vector(63 downto 0);
    
    -- port C writer 1 - Input FSM
    i_cw1_wen    : in  std_logic;
    i_cw1_wdata  : in  std_logic_vector( 4 downto 0)
  );
end acknowledge_buffer;

architecture rtl of acknowledge_buffer is

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
  signal A_ADDR    : std_logic_vector( 6 downto 0);
  signal A_BLK     : std_logic_vector( 1 downto 0);
  signal C_ADDR    : std_logic_vector( 6 downto 0);
  signal C_DIN     : std_logic_vector(35 downto 0);
  signal C_WEN     : std_logic;
  signal C_BLK     : std_logic_vector( 1 downto 0);

  -- state signals for requests
  signal A_RSTR    : unsigned(READ_LATENCY downto 0); -- track any read
  signal A_CK_RSTR : unsigned(READ_LATENCY downto 0); -- track a checksum read request

  -- checksum signals from acknowledge buffer
  signal A_DOUT    : std_logic_vector(35 downto 0);
  signal A_RDATA   : std_logic_vector(31 downto 0);
  signal A_R_CKSUM : std_logic_vector(31 downto 0);

begin

  -------------------------
  -- Adjacent processing --
  -------------------------

  -- process reads from the Output FSM
  A_RDATA <= A_DOUT(33 downto 18) & A_DOUT(15 downto 0);
  p_output_fsm_read : process(i_macclk, i_rst_n)
  begin
    if (i_rst_n = '0') then
      -- reset internal signals
      A_RSTR    <= (others => '0');
      A_CK_RSTR <= (others => '0');
      A_R_CKSUM <= (others => '0');

      -- reset output signals
      o_ar_rdata  <= (others => '0');
      o_ar_rvalid <= '0';
    elsif (i_macclk'event and i_macclk = '1') then
      -- shift read string to represent one cycle passing in a read
      A_RSTR(READ_LATENCY-1 downto 0)    <= A_RSTR(READ_LATENCY downto 1);
      A_CK_RSTR(READ_LATENCY-1 downto 0) <= A_CK_RSTR(READ_LATENCY downto 1);

      -- process new read
      if (i_ar_ren = '1') then
        -- start counter for read
        A_RSTR(READ_LATENCY) <= '1';

        -- start counter for checksum read
        if (i_ar_addr = "111") then
          A_CK_RSTR(READ_LATENCY) <= '1';
        else
          A_CK_RSTR(READ_LATENCY) <= '0';
        end if;
      else
        -- no new read
        A_RSTR(READ_LATENCY)    <= '0';
        A_CK_RSTR(READ_LATENCY) <= '0';
      end if;

      -- process completed read
      o_ar_rvalid <= A_RSTR(0);
      if (A_RSTR(0) = '1') then
        if (A_CK_RSTR(0) = '1') then
          -- output checksum
          o_ar_rdata <= A_R_CKSUM;

          -- clear checksum
          A_R_CKSUM <= (others => '0');
        else
          -- output read data from memory
          o_ar_rdata <= A_RDATA;

          -- update checksum
          A_R_CKSUM <= A_R_CKSUM xor A_RDATA;
        end if;
      end if;
    end if;
  end process;
  
  ----------------------------
  -- Internal memory blocks --
  ----------------------------

  A_ADDR <= "0000" & i_ar_addr;
  A_BLK  <= i_ar_ren & i_ar_ren;

  -- bits [15:0]
  ACK_BUF_0 : RTG4uSRAM_0
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
      -- port A (reader) - Output FSM
      A_ADDR        => A_ADDR,
      A_BLK         => A_BLK,
      A_DOUT        => A_DOUT(17 downto 0),
      A_DOUT_EN     => '1',
      A_DOUT_SRST_N => i_rst_n,
      A_CLK         => i_macclk,
      A_ADDR_EN     => '1',
      A_SB_CORRECT  => open,
      A_DB_DETECT   => open,

      -- port B (reader) - unused
      B_ADDR        => (others => '0'),
      B_BLK         => "00",
      B_DOUT        => open,
      B_DOUT_EN     => '0',
      B_DOUT_SRST_N => i_rst_n,
      B_CLK         => '1', -- clockgate to reduce power
      B_ADDR_EN     => '0',
      B_SB_CORRECT  => open,
      B_DB_DETECT   => open,

      -- port C (writer)
      C_ADDR        => C_ADDR,
      C_CLK         => i_macclk,
      C_DIN         => C_DIN(17 downto 0),
      C_WEN         => C_WEN,
      C_BLK         => C_BLK,

      -- common signals
      ARST_N        => i_rst_n,
      BUSY          => open
    );
    
  -- bits [31:16]
  ACK_BUF_1 : RTG4uSRAM_0
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
      -- port A (reader) - Output FSM
      A_ADDR        => A_ADDR,
      A_BLK         => A_BLK,
      A_DOUT        => A_DOUT(35 downto 18),
      A_DOUT_EN     => '1',
      A_DOUT_SRST_N => i_rst_n,
      A_CLK         => i_macclk,
      A_ADDR_EN     => '1',
      A_SB_CORRECT  => open,
      A_DB_DETECT   => open,

      -- port B (reader) - unused
      B_ADDR        => (others => '0'),
      B_BLK         => "00",
      B_DOUT        => open,
      B_DOUT_EN     => '0',
      B_DOUT_SRST_N => i_rst_n,
      B_CLK         => '1', -- clockgate to reduce power
      B_ADDR_EN     => '0',
      B_SB_CORRECT  => open,
      B_DB_DETECT   => open,

      -- port C (writer)
      C_ADDR        => C_ADDR,
      C_CLK         => i_macclk,
      C_DIN         => C_DIN(35 downto 18),
      C_WEN         => C_WEN,
      C_BLK         => C_BLK,

      -- common signals
      ARST_N        => i_rst_n,
      BUSY          => open
    );

end rtl;
