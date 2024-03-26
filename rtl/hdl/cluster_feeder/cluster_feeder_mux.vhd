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
		i_zero, i_one: in STD_LOGIC_VECTOR (7 downto 0);
		o_pixel: out STD_LOGIC_VECTOR (7 downto 0));
end cluster_feeder_mux;

architecture rtl of cluster_feeder_mux is
begin

  p_main: process(clk)
  begin
    if(rising_edge(clk)) then
      if (sel = '1') then
        o_pixel <= i_one;
      elsif (sel = '0') then
        o_pixel <= i_zero;
      end if;
    end if;
  end process;

end rtl;
