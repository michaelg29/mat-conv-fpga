
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




entity math_block is port ( i_a1, i_b1, i_a2, i_b2 : in signed(8 downto 0); 
                            i_c, i_d: in signed(43 downto 0);
                            i_clk : in std_logic;
                            o_p: out signed(43 downto 0)); 
end math_block; 

architecture math_block_arch of math_block is 

signal a1, b1, a2, b2 : signed(8 downto 0); 
signal c, d: signed(43 downto 0);

begin
    o_p <= (a1*b1) + (a2*b2) + c + d;
    process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            a1<=i_a1;
            b1<=i_b1;
            a2<=i_a2;
            b2<=i_b2;
            c<=i_c;
            d<=i_d;
        end if;
    end process;
end math_block_arch;
