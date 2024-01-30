library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cluster_feeder_mux is 
	port(sel, clk: in STD_LOGIC;
		A, B: in STD_LOGIC_VECTOR (7 downto 0);
		o_pixel: out STD_LOGIC_VECTOR (7 downto 0));
end cluster_feeder_mux;

architecture Behavioral of cluster_feeder_mux is
begin
process(sel, clk)
begin
	
	if(rising_edge(clk)) then
	if (sel = '1') then
	o_pixel <= A;
	elsif (sel = '0') then
	o_pixel <= B;
	end if;
end if;
end process;
end Behavioral;
