
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library mac_library;
use mac_library.mac_pkg.all;

library fifo_library;

entity core is
  generic (
    -- size of dot product
    N       : integer := 16;
    -- bit-width of each element
    W_EL    : integer := 8;
    -- number of elements that can be written at once
    N_IN_EL : integer := 8
  );
  port (
    -- Asynchronous
    i_rst_n  : in  std_logic;
    
    -- Bus clock domain
    i_bclk   : in  std_logic;
    i_asel   : in  std_logic;
    i_bsel   : in  std_logic;
    i_bdata  : in  std_logic_vector(W_EL*N_IN_EL-1 downto 0);
    o_res    : out std_logic_vector(W_EL-1 downto 0);
    o_done   : out std_logic;
    
    -- Multiplier clock domain
    i_macclk : in  std_logic 
  );
end core;

architecture rtl of core is
    
  constant W_IN   : integer := W_EL * N_IN_EL;
  constant N_BITS : integer := integer(ceil(log2(real(N/N_IN_EL))));
 
  signal counter   : unsigned(N_BITS downto 0) := (others => '0');
  signal inc       : unsigned(0 downto 0);

  signal en        : std_logic;
  signal acc       : std_logic := '0';
  signal a         : std_logic_vector(W_EL-1 downto 0);
  signal b         : std_logic_vector(W_EL-1 downto 0);
  signal aempty    : std_logic;
  signal bempty    : std_logic;

  signal mac_res   : std_logic_vector(W_EL-1 downto 0);
  
begin
  
  -- output status
  inc <= "1" when counter(N_BITS) = '0' else "0";
  o_done <= counter(N_BITS);

  -- internal counter
  p_count : process (i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0') then
        counter <= (others => '0');
        acc     <= '0';
        en      <= '0';
      else
        -- internal enable
        en <= not(aempty or bempty);
        if (en = '1') then
          counter <= counter + inc;
          acc     <= '1';
        else
          counter <= counter;
          acc     <= acc;
        end if;
      end if;
    end if;
  end process;
  
  -- FIFO A
  fifo_a : entity fifo_library.fifo_async_multw
    generic map (
      ADDR_WIDTH => N_BITS,
      W_EL       => W_EL,
      N_IN_EL    => N_IN_EL
    ) port map (
      i_rst_n  => i_rst_n,
      
      i_rclk   => i_macclk,
      i_ren    => en,
      o_rdata  => a,
      o_empty  => aempty,
      o_rvalid => open,
      o_rerr   => open,
      
      i_wclk   => i_bclk,
      i_wdata  => i_bdata,
      i_wen    => i_asel,
      o_full   => open,
      o_wvalid => open,
      o_werr   => open
    );
    
  -- FIFO B
  fifo_b : entity fifo_library.fifo_async_multw
    generic map (
      ADDR_WIDTH => N_BITS,
      W_EL       => W_EL,
      N_IN_EL    => N_IN_EL
    ) port map (
      i_rst_n  => i_rst_n,
      
      i_rclk   => i_macclk,
      i_ren    => en,
      o_rdata  => b,
      o_empty  => bempty,
      o_rvalid => open,
      o_rerr   => open,
      
      i_wclk   => i_bclk,
      i_wdata  => i_bdata,
      i_wen    => i_bsel,
      o_full   => open,
      o_wvalid => open,
      o_werr   => open
    );

  -- computational element
  core_mac : entity mac_library.mac
    generic map (
      W => W_EL
    ) port map (
      i_clk  => i_macclk,
      i_mult => en,
      i_acc  => acc,
      i_a    => a,
      i_b    => b,
      o_f    => mac_res
    );
  o_res <= (others => '0') when i_rst_n = '0' else mac_res;

end rtl;
