
library ieee;
use ieee.std_logic_1164.all;

-- Top-level constant definitions
package mat_conv_pkg is

  ------------------------------------------
  ------- command and status constants -----
  ------------------------------------------

  -- expected values
  constant MC_CMD_S_KEY     : std_logic_vector(31 downto 0) := x"CAFECAFE";
  constant MC_CMD_E_KEY     : std_logic_vector(31 downto 0) := x"DEADBEEF";
  constant MC_CMD_CMD_KERN  : std_logic := '0';
  constant MC_CMD_CMD_SUBJ  : std_logic := '1';
  
  -- error codes
  constant MC_STAT_NBITS    : integer                       := 4;
  constant MC_STAT_OKAY     : std_logic_vector(31 downto 0) := x"00000000";
  constant MC_STAT_ERR_PROC : std_logic_vector(31 downto 0) := x"00000001";
  constant MC_STAT_ERR_KEY  : std_logic_vector(31 downto 0) := x"00000002";
  constant MC_STAT_ERR_SIZE : std_logic_vector(31 downto 0) := x"00000004";
  constant MC_STAT_ERR_CKSM : std_logic_vector(31 downto 0) := x"00000008";
    
end package mat_conv_pkg;
