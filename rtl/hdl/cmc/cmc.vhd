library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.all;

entity cmc is
    port(i_addr: in std_logic_vector(10 downto 0);
        i_core_0, i_core_1, i_core_2,i_core_3, i_core_4: in std_logic_vector(17 downto 0);
        o_core_0, o_core_1, o_core_2,o_core_3, o_core_4, o_pixel: out std_logic_vector(17 downto 0);
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
      
      -- SB_CORRECT and DB_DETECT signal for ECC
      signal a0_sb, b0_sb,a1_sb, b1_sb, a2_sb, b2_sb, a3_sb, b3_sb: std_logic;
      signal a0_db, b0_db,a1_db, b1_db, a2_db, b2_db, a3_db, b3_db: std_logic;
      signal lsram_read: std_logic;
      signal lsram_write: std_logic_vector (1 downto 0);

      -- Address signal
      signal i_read_addr: std_logic_vector(10 downto 0);
      signal i_write_addr: std_logic_vector(10 downto 0);
      signal i_addr_delay1: std_logic_vector(10 downto 0);

      -- Valid write signal 
      signal i_val_write: std_logic;
      signal i_val_delay1: std_logic := 'X';

      begin

        -- i_core_0 and o_core 4 assignment
        o_core_0 <= (others => '0');
        i_read_addr <= i_addr;


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
            A_ADDR => i_read_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_1,
            A_WEN => (others => '0'),
            A_REN => lsram_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_write_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_0,
            B_DOUT => open, 
            B_WEN => lsram_write,
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
            A_ADDR => i_read_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_2,
            A_WEN => (others => '0'),
            A_REN => lsram_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_write_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_1,
            B_DOUT => open, 
            B_WEN => lsram_write,
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
            A_ADDR => i_read_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_3,
            A_WEN => (others => '0'),
            A_REN => lsram_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_write_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_2,
            B_DOUT => open, 
            B_WEN => lsram_write,
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
            A_ADDR => i_read_addr,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_4,
            A_WEN => (others => '0'),
            A_REN => lsram_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_write_addr,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_3,
            B_DOUT => open, 
            B_WEN => lsram_write,
            B_REN => '0',
            B_DOUT_EN => '0',
            B_DOUT_SRST_N => '1',
            B_SB_CORRECT => open,
            B_DB_DETECT => open,
            ARST_N => '1',
            BUSY => open);
        
        
        -- Processes to delay i_val and i_addr for two clock cycles for write operation
        i_val_write_delay: process(i_val, i_clk)
        begin
            if rising_edge(i_clk) and i_en = '1' then
                i_val_delay1 <= i_val;
                i_val_write <= i_val_delay1;
            end if;
        end process;

        i_addr_write_delay: process (i_addr, i_clk)
        begin
            if rising_edge(i_clk) and i_en = '1' then
                i_addr_delay1 <= i_addr;
                i_write_addr <= i_addr_delay1;
            end if;
        end process;

        -- LSRAM read and write processes
        lsram_process: process(i_val,i_val_write,i_clk)
        begin
            if rising_edge(i_clk) and i_en = '1' then 

                --Read enable
                if i_val = '1' then
                    lsram_read <= '1';
                else 
                    lsram_read <= '0';
                end if;

                --Write enable
                if i_val_write = '1' then
                    lsram_write <= "11";
                else
                    lsram_write <= "00";
                end if;

            end if;
        end process;   
        
        o_pixel_process: process(i_en, i_clk,i_val_write)
        begin
            if rising_edge(i_clk) and i_en = '1' and i_val_write = '1' then
                o_pixel <= i_core_4;
            end if;
        end process;


end rtl;
