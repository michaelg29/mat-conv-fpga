-----------------------------------------
--2to1 multiplexer structural TestBench--
-----------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity testbench_core is
-- empty
end testbench_core;

architecture tb of testbench_core is

--Device Under Test component
--component core is port ( i_clk, i_en: in std_logic;
--                      i_k0, i_k1, i_k2, i_k3, i_k4, i_s0, i_s1, i_s2, i_s3, i_s4 : in std_logic_vector(7 downto 0); 
--                      i_sub: in std_logic_vector(17 downto 0);
--                      o_res: out std_logic_vector(17 downto 0)); 
--end component; 

signal i_clk, i_en : std_logic;
signal i_k0, i_k1, i_k2, i_k3, i_k4, i_s0, i_s1, i_s2, i_s3, i_s4 : std_logic_vector(7 downto 0); 
signal i_sub : std_logic_vector(17 downto 0);
signal o_res : std_logic_vector(17 downto 0);

begin

	--Connect DUT
    DUT: entity work.core 
    generic map (i_round => (7 => '1', others => '0'))
    port map (i_clk => i_clk, i_en => i_en,
                        i_k0 => i_k0, i_k1 => i_k1, i_k2 => i_k2, i_k3 => i_k3, i_k4 => i_k4, 
                        i_s0 => i_s0, i_s1 => i_s1, i_s2 => i_s2, i_s3 => i_s3, i_s4 => i_s4, 
                        i_sub => i_sub, o_res => o_res);

    clk_process: process
		begin
        i_clk <= '1';
    	wait for 2 ns;
    	i_clk <= '0';
    	wait for 2 ns;
	end process;

    process
    begin
        i_en <= '0';
        i_k0 <= (others => '0');
        i_k1 <= (others => '0');
        i_k2 <= (others => '0');
        i_k3 <= (others => '0');
        i_k4 <= (others => '0');          
        i_s0 <= (others => '0');
        i_s1 <= (others => '0');
        i_s2 <= (others => '0');
        i_s3 <= (others => '0');        
        i_s4 <= (others => '0');
        i_sub <= (others => '0');
        wait for 16 ns;

        i_en <= '1';
        i_k0 <= std_logic_vector(to_signed(127, 8));-- 0.9921875 in signed Q0.7
        i_s0 <= std_logic_vector(to_signed(10, 8));
        wait for 8 ns;

        i_k1 <= std_logic_vector(to_signed(127, 8));-- 0.9921875 in signed Q0.7
        i_s1 <= std_logic_vector(to_signed(10, 8));
        wait for 8 ns;

        i_k2 <= std_logic_vector(to_signed(127, 8));-- 0.9921875 in signed Q0.7
        i_s2 <= std_logic_vector(to_signed(10, 8));
        wait for 8 ns;

        i_k3 <= std_logic_vector(to_signed(127, 8));-- 0.9921875 in signed Q0.7
        i_s3 <= std_logic_vector(to_signed(10, 8));
        wait for 8 ns;

        i_k4 <= std_logic_vector(to_signed(127, 8));-- 0.9921875 in signed Q0.7
        i_s4 <= std_logic_vector(to_signed(10, 8));
        wait for 8 ns;

        
        i_sub <= std_logic_vector(to_signed(127, 18));
        wait for 24 ns;
        
        ---Clear inputs
        i_k0 <= (others => '0');
        i_k1 <= (others => '0');
        i_k2 <= (others => '0');
        i_k3 <= (others => '0');
        i_k4 <= (others => '0');          
        i_s0 <= (others => '0');
        i_s1 <= (others => '0');
        i_s2 <= (others => '0');
        i_s3 <= (others => '0');        
        i_s4 <= (others => '0');
        i_sub <= (others => '0');        
        wait;
	end process;
end tb;
