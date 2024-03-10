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
      signal lsram0_read, lsram1_read, lsram2_read, lsram3_read: std_logic;
      signal lsram0_write, lsram1_write, lsram2_write, lsram3_write: std_logic_vector (1 downto 0);

      -- Address process states
      signal i_addr_signal : std_logic_vector(10 downto 0);
      type addr_state is (initial, new_addr, latch_addr);
      signal address_state: addr_state;

      -- Read and write proces states
      type read_and_write_state is (initial, 
                            write_0_s, write_0_c, read_0_s, read_0_c,
                            write_1_s, write_1_c, read_1_s, read_1_c,
                            write_2_s, write_2_c, read_2_s, read_2_c,
                            write_3_s, write_3_c, read_3_s, read_3_c);
      signal lsram_state: read_and_write_state;

      -- signal for clock latch
      -- signal clk_latch: std_logic;

      begin

        -- i_core_0 and o_core 4 assignment
        o_core_0 <= (others => '0');
        o_pixel <= i_core_4;

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
            A_ADDR => i_addr_signal,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_1,
            A_WEN => (others => '0'),
            A_REN => lsram0_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr_signal,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_0,
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
            A_ADDR => i_addr_signal,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_2,
            A_WEN => (others => '0'),
            A_REN => lsram1_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr_signal,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_1,
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
            A_ADDR => i_addr_signal,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_3,
            A_WEN => (others => '0'),
            A_REN => lsram2_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr_signal,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_2,
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
            A_ADDR => i_addr_signal,
            A_BLK => blk_const,
            A_CLK => i_clk,
            A_DIN => (others => 'X'),
            A_DOUT => o_core_4,
            A_WEN => (others => '0'),
            A_REN => lsram3_read,
            A_DOUT_EN => '1',
            A_DOUT_SRST_N => '1',
            A_SB_CORRECT => open,
            A_DB_DETECT => open,
            B_ADDR => i_addr_signal,
            B_BLK => blk_const,
            B_CLK => i_clk,
            B_DIN => i_core_3,
            B_DOUT => open, 
            B_WEN => lsram3_write,
            B_REN => '0',
            B_DOUT_EN => '0',
            B_DOUT_SRST_N => '1',
            B_SB_CORRECT => open,
            B_DB_DETECT => open,
            ARST_N => '1',
            BUSY => open);
        
        -- LSRAM address FSM to latch address for one extra clock cycle
        lsram_address_state   : process(i_clk, i_val, i_en)
        begin
            if rising_edge(i_clk) and i_en = '1' then
            case address_state is
                when initial =>
                    if i_val = '1' then address_state <= new_addr; end if;
                when new_addr =>
                    address_state <= latch_addr; 
                when latch_addr =>
                    address_state <= initial;
                end case;
            end if;
        end process;

        lsram_address_value : process(address_state)
        begin
            if rising_edge(i_clk) and i_en = '1' then
                case address_state is
                    when initial => i_addr_signal <= (others => 'X');
                    when new_addr => i_addr_signal <= i_addr;
                    when latch_addr => i_addr_signal <= i_addr;
                end case;
            end if;
        end process;


        -- LSRAM read and write FSM 
        lsram_read_and_write_state: process(i_clk, i_val, i_en)
        begin
            if rising_edge(i_clk) and i_en = '1' then
            case lsram_state is
                when initial =>
                    if i_val = '1' then lsram_state <= write_0_s; 
                    else lsram_state <= initial; end if;
                when write_0_s => lsram_state <= write_0_c;
                when write_0_c => lsram_state <= read_0_s;
                when read_0_s => lsram_state <= read_0_c;
                when read_0_c => lsram_state <= write_1_s;
                when write_1_s => lsram_state <= write_1_c;
                when write_1_c => lsram_state <= read_1_s;
                when read_1_s => lsram_state <= read_1_c;
                when read_1_c => lsram_state <= write_2_s;
                when write_2_s => lsram_state <= write_2_c;
                when write_2_c => lsram_state <= read_2_s;
                when read_2_s => lsram_state <= read_2_c;
                when read_2_c => lsram_state <= write_3_s;
                when write_3_s => lsram_state <= write_3_c;
                when write_3_c => lsram_state <= read_3_s;
                when read_3_s => lsram_state <= read_3_c;
                when read_3_c => lsram_state <= initial;
                end case;
            end if;
        end process;

        lsram_read_and_write: process(lsram_state)
        begin
            if rising_edge(i_clk) and i_en = '1' then
            case lsram_state is
                when initial => lsram3_read <= '0';
                when write_0_s => lsram0_write <= "11";
                when write_0_c => lsram0_write <= "11";
                when read_0_s =>
                    lsram0_write <= "00";
                    lsram0_read <= '1';
                when read_0_c => lsram0_read <= '1';
                when write_1_s =>
                    lsram0_read <= '0';
                    lsram1_write <= "11";
                when write_1_c => lsram1_write <= "11";
                when read_1_s => 
                    lsram1_write <= "00";
                    lsram1_read <= '1';
                when read_1_c => lsram1_read <= '1';
                when write_2_s => 
                    lsram1_read <= '0';
                    lsram2_write <= "11";
                when write_2_c => lsram2_write <= "11";
                when read_2_s =>
                    lsram2_write <= "00";
                    lsram2_read <= '1';
                when read_2_c => lsram2_read <= '1';
                when write_3_s => 
                    lsram2_read <= '0';
                    lsram3_write <= "11";
                when write_3_c => lsram3_write <= "11";
                when read_3_s =>
                    lsram3_write <= "00";
                    lsram3_read <= '1';
                when read_3_c => lsram3_read <= '1';
                end case;
            end if;
        end process;

                


end rtl;
