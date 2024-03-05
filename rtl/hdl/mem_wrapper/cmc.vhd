library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.all;

entity cmc is
    port(i_addr: in std_logic_vector(10 downto 0);
        i_core0, i_core1, i_core2,i_core3, i_core4: in std_logic_vector(17 downto 0);
        o_core0, o_core1, o_core2,o_core3, o_core4: out std_logic_vector(17 downto 0);
        i_clk, i_en: in std_logic;
        i_val: in std_logic);
end cmc;

architecture rtl of cmc is
    component lsram_1024x18 is
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
      end component;

      -- BLK signal
      signal blk_const: std_logic_vector (2 downto 0) := (others => '1');
      -- SB_CORRECT and DB_DETECT signal
      signal a0_sb, b0_sb,a1_sb, b1_sb, a2_sb, b2_sb, a3_sb, b3_sb: std_logic;
      signal a0_db, b0_db,a1_db, b1_db, a2_db, b2_db, a3_db, b3_db: std_logic;
      signal lsram0_read, lsram1_read, lsram2_read, lsram3_read: std_logic;
      signal lsram0_write, lsram1_write, lsram2_write, lsram3_write: std_logic_vector (1 downto 0);

      begin 
        lsram_0: lsram_1024x18
        generic map(
            A_WIDTH => "01",
            A_WMODE => "00",
            A_DOUT_BYPASS => '0',
	        B_WIDTH => "01",
            B_WMODE => "00",
            B_DOUT_BYPASS => '0',
            DELEN => '0',
            SECURITY => '0'
        )
        port map(
            A_ADDR => i_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core1,
            A_WEN => (others => '0'),
            A_REN => lsram0_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core0,
            B_DOUT => open, 
            B_WEN => lsram0_write,
            B_REN => '0',
            B_DOUT_EN => '0',
            B_DOUT_SRST_N => '1',
            B_SB_CORRECT => open,
            B_DB_DETECT => open,
            ARST_N => '1',
            BUSY => open);

        lsram_1: lsram_1024x18
        generic map(
            A_WIDTH => "01",
            A_WMODE => "00",
            A_DOUT_BYPASS => '0',
	        B_WIDTH => "01",
            B_WMODE => "00",
            B_DOUT_BYPASS => '0',
            DELEN => '0',
            SECURITY => '0'
        )
        port map(
            A_ADDR => i_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core2,
            A_WEN => (others => '0'),
            A_REN => lsram1_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core1,
            B_DOUT => open, 
            B_WEN => lsram1_write,
            B_REN => '0',
            B_DOUT_EN => '0',
            B_DOUT_SRST_N => '1',
            B_SB_CORRECT => open,
            B_DB_DETECT => open,
            ARST_N => '1',
            BUSY => open);

        lsram_2: lsram_1024x18
        generic map(
            A_WIDTH => "01",
            A_WMODE => "00",
            A_DOUT_BYPASS => '0',
            B_WIDTH => "01",
            B_WMODE => "00",
            B_DOUT_BYPASS => '0',
            DELEN => '0',
            SECURITY => '0'
            )
        port map(
            A_ADDR => i_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core3,
            A_WEN => (others => '0'),
            A_REN => lsram2_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core2,
            B_DOUT => open, 
            B_WEN => lsram2_write,
            B_REN => '0',
            B_DOUT_EN => '0',
            B_DOUT_SRST_N => '1',
            B_SB_CORRECT => open,
            B_DB_DETECT => open,
            ARST_N => '1',
            BUSY => open);

        lsram_3: lsram_1024x18
        generic map(
            A_WIDTH => "01",
            A_WMODE => "00",
            A_DOUT_BYPASS => '0',
            B_WIDTH => "01",
            B_WMODE => "00",
            B_DOUT_BYPASS => '0',
            DELEN => '0',
            SECURITY => '0'
        )
        port map(
            A_ADDR => i_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core4,
            A_WEN => (others => '0'),
            A_REN => lsram3_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core3,
            B_DOUT => open, 
            B_WEN => lsram3_write,
            B_REN => '0',
            B_DOUT_EN => '0',
            B_DOUT_SRST_N => '1',
            B_SB_CORRECT => open,
            B_DB_DETECT => open,
            ARST_N => '1',
            BUSY => open);
        
            

end rtl;
