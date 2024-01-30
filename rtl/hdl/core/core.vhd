
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




entity core is port ( i_clk, i_en, i_rst_n : in std_logic;
                      i_k0, i_k1, i_k2, i_k3, i_k4, i_s0, i_s1, i_s2, i_s3, i_s4 : in signed(7 downto 0); 
                      i_sub: in signed(17 downto 0);
                      o_valid : out std_logic;
                      o_res: out signed(17 downto 0)); 
end core; 

architecture core_arch of core is 


component math_block is port ( A1, B1, A2, B2 : in signed(8 downto 0); 
                                C, D: in signed(43 downto 0);
                                clk : in std_logic;
                                P: out signed(43 downto 0)); 
end component; 

signal k4_p_reg, s4_p_reg : signed(8 downto 0); --pipelining regs for 2nd mathblock
--signal mult : signed(17 downto 0);



signal MAC0_A1, MAC0_B1, MAC0_A2, MAC0_B2 : signed(8 downto 0); 
signal MAC0_C, MAC0_P : signed(43 downto 0);

signal MAC1_A1, MAC1_B1, MAC1_A2, MAC1_B2 : signed(8 downto 0); 
signal MAC1_P : signed(43 downto 0);

signal MAC2_A2, MAC2_B2 : signed(8 downto 0); 
signal MAC2_P : signed(43 downto 0);


  begin 


  MAC0 : math_block port map ( A1 => MAC0_A1, B1 => MAC0_B1, A2 => MAC0_A2, B2 => MAC0_B2, 
                               C => MAC0_C, D => (others => '0'), clk => i_clk, P => MAC0_P);

  MAC1 : math_block port map ( A1 => MAC1_A1, B1 => MAC1_B1, A2 => MAC1_A2, B2 => MAC1_B2, 
                               C => (2 => '1', others => '0'), D => (others => '0'), clk => i_clk, P => MAC1_P);--ADD ROUNDING INTO PORT C

  MAC2 : math_block port map ( A1 => (others => '0'), B1=> (others => '0'), A2 => MAC2_A2, B2 => MAC2_B2, 
                               C => MAC0_P, D => MAC1_P, clk => i_clk, P => MAC2_P);



  process(i_clk)
    begin
      if(rising_edge(i_clk)) then 
        if(i_rst_n = '0') then
          k4_p_reg <= (others => '0');
          s4_p_reg <= (others => '0');
          MAC0_A1 <= (others => '0');
          MAC0_B1 <= (others => '0');
          MAC0_A2 <= (others => '0');
          MAC0_B2 <= (others => '0');
          MAC0_C <= (others => '0');          
          MAC1_A1 <= (others => '0');
          MAC1_B1 <= (others => '0');
          MAC1_A2 <= (others => '0');
          MAC1_B2 <= (others => '0');        
          MAC2_A2 <= (others => '0');
          MAC2_B2 <= (others => '0');
          o_res <= (others => '0');
          o_valid <= '0';

        elsif(i_en = '1') then

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

          o_res <= MAC2_P(20 downto 3); --(28 down to 11) should be the real result since math blocks in DOTP mode output on the upper 36 bits          
          o_valid <= '1';
        end if;
      end if;
  end process;

end core_arch;
