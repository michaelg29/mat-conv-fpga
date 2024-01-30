library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cluster_feeder_flipflop is
    port(clk: in std_logic;
        i_pixel: in std_logic_vector (7 downto 0);
        o_pixel: out std_logic_vector (7 downto 0));
end cluster_feeder_flipflop;

architecture Behavioral of cluster_feeder_flipflop is
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            o_pixel <= i_pixel;
        end if;
    end process;
end Behavioral;