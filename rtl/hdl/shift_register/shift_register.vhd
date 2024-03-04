
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity shift_register is 
  generic (
        WIDTH : integer := 1
    );
  port ( 
    i_clk : in std_logic;
    i_val: in std_logic_vector(WIDTH-1 downto 0); 
    o_val: out std_logic_vector(WIDTH-1 downto 0)); 
end shift_register; 

architecture arch of shift_register is 
  begin 

    process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            o_val <= i_val;
        end if;
    end process;

end arch;
