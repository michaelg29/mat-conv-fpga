
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




entity saturator is port (i_clk, i_sign : in std_logic;
                          i_val : in std_logic_vector(17 downto 0);
                          o_res : out std_logic_vector(7 downto 0)); 
end saturator; 

architecture saturator_arch of saturator is 

  begin 

  process(i_clk)
    begin
      if(rising_edge(i_clk)) then 
        if i_sign = '0' then --clamp unsigned. Value cant be negative, only have to check the upper bound
          if i_val(17 downto 12) = "000000" then
            o_res <= i_val(11 downto 4);
          else 
            o_res <= "11111111";
          end if;

        else --clamp signed. check both bounds

          if i_val(17) = '1' then --negative number, clamp to -128
            if (i_val(16 downto 11) and "111111") = "111111" then
              o_res <= i_val(11 downto 4);
            else 
              o_res <= "10000000";
            end if;

          else --positive number, clamp to 127
            if i_val(16 downto 11) = "000000" then
              o_res <= i_val(11 downto 4);
            else 
              o_res <= "01111111";
            end if;

          end if;
        end if;
      end if;
  end process;

end saturator_arch;
