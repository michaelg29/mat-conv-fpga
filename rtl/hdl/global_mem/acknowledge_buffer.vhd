
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
    i_cw1_addr   : in  std_logic_vector( 1 downto 0);
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
  signal A_DOUT    : std_logic_vector(35 downto 0);
  signal C_ADDR_US : unsigned(2 downto 0);
  signal C_ADDR    : std_logic_vector( 6 downto 0);
  signal C_DIN     : std_logic_vector(35 downto 0);
  signal C_WEN     : std_logic;
  signal C_BLK     : std_logic_vector( 1 downto 0);

  -- state signals for requests
  signal A_RSTR    : unsigned(READ_LATENCY downto 0); -- track any read
  signal A_CK_RSTR : unsigned(READ_LATENCY downto 0); -- track a checksum read request

  -- checksum signals from acknowledge buffer
  signal A_RDATA   : std_logic_vector(31 downto 0);
  signal A_R_CKSUM : std_logic_vector(31 downto 0);

  -- CDC signals for AXI Rx
  signal cw0_addr_cdc    : std_logic_vector( 3 downto 0);
  signal cw0_wen_cdc     : std_logic;
  signal cw0_wdata_cdc   : std_logic_vector(63 downto 0);
  signal cw0_wdata_hi_en : std_logic; -- write the high 32-bit word

begin

  -------------------------
  -- Adjacent processing --
  -------------------------

  -- process reads from the Output FSM
  A_RDATA <= A_DOUT(33 downto 18) & A_DOUT(15 downto 0);
  p_port_a_read : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0') then
        -- reset internal signals
        A_RSTR    <= (others => '0');
        A_CK_RSTR <= (others => '0');
        A_R_CKSUM <= (others => '0');

        -- reset output signals
        o_ar_rdata  <= (others => '0');
        o_ar_rvalid <= '0';
      else
        -- shift read string to represent one cycle passing in a read
        A_RSTR(READ_LATENCY-1 downto 0)    <= A_RSTR(READ_LATENCY downto 1);
        A_CK_RSTR(READ_LATENCY-1 downto 0) <= A_CK_RSTR(READ_LATENCY downto 1);

        -- start counter for read
        A_RSTR(READ_LATENCY) <= i_ar_ren;
        if (i_ar_ren = '1' and i_ar_addr = "111") then
          -- start counter for checksum read
          A_CK_RSTR(READ_LATENCY) <= '1';
        else
          -- no new read
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
        else
          A_R_CKSUM <= A_R_CKSUM;
        end if;
      end if;
    end if;
  end process;

  -- arbitrate writes from AXI Rx and Input FSM
  p_axi_rx_write : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0') then
        -- reset CDC signals
        cw0_addr_cdc    <= (others => '0');
        cw0_wen_cdc     <= '0';
        cw0_wdata_cdc   <= (others => '0');
        cw0_wdata_hi_en <= '0';

        -- reset memory port signals
        C_DIN           <= (others => '0');
        C_WEN           <= '0';
        C_ADDR_US       <= (others => '0');
      else
        -- CDC
        cw0_addr_cdc  <= i_cw0_addr;
        cw0_wen_cdc   <= i_cw0_wen;
        cw0_wdata_cdc <= i_cw0_wdata;

        -- process AXI Rx write to the command space
        if (cw0_wen_cdc = '1' and cw0_addr_cdc(3) = '1') then
          -- shift register CDC data
          if (cw0_wdata_hi_en = '0') then
            -- least significant bits
            C_DIN(15 downto  0) <= cw0_wdata_cdc(15 downto 0);
            C_DIN(33 downto 18) <= cw0_wdata_cdc(31 downto 16);
            C_WEN               <= '1';
            C_ADDR_US           <= unsigned(cw0_addr_cdc(2 downto 0));
            cw0_wdata_hi_en     <= '1';
          else
            -- most significant bits
            C_DIN(15 downto  0) <= cw0_wdata_cdc(47 downto 32);
            C_DIN(33 downto 18) <= cw0_wdata_cdc(63 downto 48);
            C_WEN               <= '1';
            C_ADDR_US           <= C_ADDR_US + 1; -- write to second 32-bit word
            C_ADDR(2 downto 0)  <= cw0_addr_cdc(2 downto 0);
            cw0_wdata_hi_en     <= '0';
          end if;
        -- process Input FSM write to state register (copy to STATUS_reg)
        elsif (i_cw1_wen = '1' and i_cw1_addr = "00") then
          -- copy 5 bits of write data
          C_DIN( 4 downto  0) <= i_cw1_wdata;
          C_DIN(15 downto  5) <= (others => '0');
          C_DIN(33 downto 18) <= (others => '0');

          -- static address for Input FSM
          C_ADDR_US           <= to_unsigned(5, 3); -- STATUS_reg is the fifth word
          C_WEN               <= '1';
        -- no write
        else
          C_WEN <= '0';
        end if;
      end if;
    end if;
  end process;

  ----------------------------
  -- Internal memory blocks --
  ----------------------------

  -- signal concatenations
  A_ADDR              <= "0000" & i_ar_addr;
  A_BLK               <= i_ar_ren & i_ar_ren;

  C_ADDR              <= "0000" & std_logic_vector(C_ADDR_US);
  C_DIN(35 downto 34) <= (others => '0');
  C_DIN(17 downto 16) <= (others => '0');
  C_BLK               <= C_WEN & C_WEN;

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
      B_CLK         => '0', -- clockgate to reduce power
      B_ADDR_EN     => '0',
      B_SB_CORRECT  => open,
      B_DB_DETECT   => open,

      -- port C (writer) - Input FSM/AXI Rx
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
      B_CLK         => '0', -- clockgate to reduce power
      B_ADDR_EN     => '0',
      B_SB_CORRECT  => open,
      B_DB_DETECT   => open,

      -- port C (writer) - Input FSM/AXI Rx
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
