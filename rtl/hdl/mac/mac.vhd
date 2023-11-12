library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mac_pkg.all;

-- f' = mult * (a * b) + acc * f
entity mac is
  generic (
    W : integer := 8
  );
  port (
    i_clk   : in  std_logic;
    i_mult  : in  std_logic;
    i_acc   : in  std_logic;
    i_a     : in  std_logic_vector(W-1 downto 0);
    i_b     : in  std_logic_vector(W-1 downto 0);
    o_f     : out std_logic_vector(W-1 downto 0)
  );
end mac;

architecture rtl of mac is

  signal a    : unsigned(  W-1 downto 0);
  signal b    : unsigned(  W-1 downto 0);
  signal c    : unsigned(2*W-1 downto 0);
  signal mode : std_logic_vector(1 downto 0);

begin

  a <= unsigned(i_a);
  b <= unsigned(i_b);
  o_f <= std_logic_vector(c(o_f'range));
  mode <= i_mult & i_acc;

  P_COMPUTE : process (i_clk)
  begin
    if (i_clk'event and i_clk = '1') then
      case mode is
        when MAC_LATCH => c <= c;
        when MAC_MULT  => c <= a * b;
        when MAC_MAC   => c <= (a * b) + c;
        when others    => c <= (others => '0'); -- MAC_RESET
      end case; -- RB_In & value
    end if;
  end process P_COMPUTE;

end rtl;