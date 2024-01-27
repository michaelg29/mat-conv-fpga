
library ieee;
use ieee.std_logic_1164.all;

package mat_conv_axi_pkg is

  --type TYPE_ARRAY_OF_32BITS is array ;
  type TYPE_ARRAY_OF_32BITS is array (INTEGER range <>) of std_logic_vector(31 downto 0);
  --type MEMORY is array (INTEGER range <>) of MY_WORD

end package mat_conv_axi_pkg;
