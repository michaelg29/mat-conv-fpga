
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




entity core is port ( i_clk, i_en : in std_logic;
                      i_k0, i_k1, i_k2, i_k3, i_k4, i_s0, i_s1, i_s2, i_s3, i_s4 : in signed(7 downto 0); 
                      i_sub: in signed(17 downto 0);
                      o_res: out signed(17 downto 0)); 
end core; 

architecture core_arch of core is 


component math_block is port (  i_a1, i_b1, i_a2, i_b2 : in signed(8 downto 0); 
                                i_c, i_d: in signed(43 downto 0);
                                i_clk : in std_logic;
                                o_p: out signed(43 downto 0));
end component; 

signal k4_p_reg, s4_p_reg : signed(8 downto 0); --pipelining regs for 2nd mathblock



signal MAC0_A1, MAC0_B1, MAC0_A2, MAC0_B2 : signed(8 downto 0); 
signal MAC0_C, MAC0_P : signed(43 downto 0);

signal MAC1_A1, MAC1_B1, MAC1_A2, MAC1_B2 : signed(8 downto 0); 
signal MAC1_P : signed(43 downto 0);

signal MAC2_A2, MAC2_B2 : signed(8 downto 0); 
signal MAC2_P : signed(43 downto 0);

  begin 


  MAC0 : math_block port map ( i_a1 => MAC0_A1, i_b1 => MAC0_B1, i_a2 => MAC0_A2, i_b2 => MAC0_B2, 
                               i_c => MAC0_C, i_d => (others => '0'), i_clk => i_clk, o_p => MAC0_P);

  MAC1 : math_block port map ( i_a1 => MAC1_A1, i_b1 => MAC1_B1, i_a2 => MAC1_A2, i_b2 => MAC1_B2, 
                               i_c => (2 => '1', others => '0'), i_d => (others => '0'), i_clk => i_clk, o_p => MAC1_P);--ADD ROUNDING INTO PORT C

  MAC2 : math_block port map ( i_a1 => (others => '0'), i_b1=> (others => '0'), i_a2 => MAC2_A2, i_b2 => MAC2_B2, 
                               i_c => MAC0_P, i_d => MAC1_P, i_clk => i_clk, o_p => MAC2_P);


o_res <= MAC2_P(20 downto 3); --(28 down to 11) should be the real result since math blocks in DOTP mode output on the upper 36 bits

  process(i_clk)
    begin
      if(rising_edge(i_clk)) then 
        if(i_en = '1') then

          MAC0_A1 <= i_k0(7) & i_k0;
          MAC0_B1 <= i_s0(7) & i_s0;
          MAC0_A2 <= i_k1(7) & i_k1;
          MAC0_B2 <= i_s1(7) & i_s1;
          MAC0_C <= resize(i_sub, 44);
          
          MAC1_A1 <= i_k2(7) & i_k2;
          MAC1_B1 <= i_s2(7) & i_s2;
          MAC1_A2 <= i_k3(7) & i_k3;
          MAC1_B2 <= i_s3(7) & i_s3;
          
          MAC2_A2 <= k4_p_reg;
          MAC2_B2 <= s4_p_reg;
          k4_p_reg <= i_k4(7) & i_k4;
          s4_p_reg <= i_s4(7) & i_s4;
          
        end if;
      end if;
  end process;

end core_arch;
