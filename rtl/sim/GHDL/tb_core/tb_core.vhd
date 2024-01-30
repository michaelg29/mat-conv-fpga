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
component core is port ( i_clk, i_en, i_rst_n : in std_logic;
                      i_k0, i_k1, i_k2, i_k3, i_k4, i_s0, i_s1, i_s2, i_s3, i_s4 : in signed(7 downto 0); 
                      i_sub: in signed(17 downto 0);
                      o_valid : out std_logic;
                      o_res: out signed(17 downto 0)); 
end component; 

signal i_clk, i_en, i_rst_n : std_logic;
signal i_k0, i_k1, i_k2, i_k3, i_k4, i_s0, i_s1, i_s2, i_s3, i_s4 : signed(7 downto 0); 
signal i_sub : signed(17 downto 0);
signal o_valid : std_logic;
signal o_res : signed(17 downto 0);

begin

	--Connect DUT
    DUT: core port map (i_clk => i_clk, i_en => i_en, i_rst_n => i_rst_n, 
                        i_k0 => i_k0, i_k1 => i_k1, i_k2 => i_k2, i_k3 => i_k3, i_k4 => i_k4, 
                        i_s0 => i_s0, i_s1 => i_s1, i_s2 => i_s2, i_s3 => i_s3, i_s4 => i_s4, 
                        i_sub => i_sub, o_valid => o_valid, o_res => o_res);

    clk_process: process
		begin
        i_clk <= '0';
    	wait for 2 ns;
    	i_clk <= '1';
    	wait for 2 ns;
	end process;

    process
    begin
    	i_rst_n <= '0';
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

        i_rst_n <= '1';
        i_en <= '1';
        i_k0 <= to_signed(127, 8);-- 0.9921875 in signed Q0.7
        i_s0 <= to_signed(10, 8);
        wait for 8 ns;

        i_k1 <= to_signed(127, 8);-- 0.9921875 in signed Q0.7
        i_s1 <= to_signed(10, 8);
        wait for 8 ns;

        i_k2 <= to_signed(127, 8);-- 0.9921875 in signed Q0.7
        i_s2 <= to_signed(10, 8);
        wait for 8 ns;

        i_k3 <= to_signed(127, 8);-- 0.9921875 in signed Q0.7
        i_s3 <= to_signed(10, 8);
        wait for 8 ns;

        i_k4 <= to_signed(127, 8);-- 0.9921875 in signed Q0.7
        i_s4 <= to_signed(10, 8);
        wait for 24 ns;
        
        ---Clear inputs
        i_rst_n <= '0';
        i_en <= '0';
        
        wait;
	end process;
end tb;
