
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




entity math_block is port ( A1, B1, A2, B2 : in signed(8 downto 0); 
                            C, D: in signed(43 downto 0);
                            clk : in std_logic;
                            P: out signed(43 downto 0)); 
end math_block; 

architecture math_block_arch of math_block is 
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            P <= (A1*B1) + (A2*B2) + C + D;
        end if;
    end process;
end math_block_arch;
