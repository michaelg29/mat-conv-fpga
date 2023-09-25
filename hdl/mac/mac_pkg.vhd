
library ieee;
use ieee.std_logic_1164.all;

package mac_pkg is

  constant MAC_RESET : std_logic_vector(1 downto 0) := "00";
  constant MAC_LATCH : std_logic_vector(1 downto 0) := "01";
  constant MAC_MULT  : std_logic_vector(1 downto 0) := "10";
  constant MAC_MAC   : std_logic_vector(1 downto 0) := "11";
    
end package mac_pkg;
