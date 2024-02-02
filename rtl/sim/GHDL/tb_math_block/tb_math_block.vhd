-----------------------------------------
--2to1 multiplexer structural TestBench--
-----------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity testbench_math_block is
-- empty
end testbench_math_block;

architecture tb of testbench_math_block is

--Device Under Test component
component math_block is port (  i_a1, i_b1, i_a2, i_b2 : in signed(8 downto 0); 
                                i_c, i_d: in signed(43 downto 0);
                                i_clk : in std_logic;
                                o_p: out signed(43 downto 0));  
end component; 

signal A1, B1, A2, B2 : signed(8 downto 0); 
signal C, D : signed(43 downto 0);
signal clk : std_logic;
signal P : signed(43 downto 0);

begin

	--Connect DUT
    DUT: math_block port map ( i_a1 => A1, i_b1 => B1, i_a2 => A2, i_b2 => B2, 
                               i_c => C, i_d => D, i_clk => clk, o_P => P);

    clk_process: process
		begin
        clk <= '0';
    	wait for 2 ns;
    	clk <= '1';
    	wait for 2 ns;
	end process;

    process
    begin
    	A1 <= (others => '0');
        B1 <= (others => '0');
        A2 <= (others => '0');
        B2 <= (others => '0');
        C <= (others => '0');
        D <= (others => '0');
        wait for 8 ns;

        A1 <= to_signed(127, 9);-- 0.9921875 in signed Q0.7
        B1 <= to_signed(90, 9);
        wait for 8 ns;
        --89.296875 -> 0b10110010100110 (2CA6)
        

        A1 <= (others => '0');
        B1 <= (others => '0');
        A2 <= to_signed(127, 9);-- 0.9921875 in signed Q0.7
        B2 <= to_signed(90, 9);
        wait for 8 ns;
        --89.296875 -> 0b10110010100110

        A2 <= (others => '0');
        B2 <= (others => '0');
        C <= to_signed(127, 44);
        wait for 8 ns;
        
        C <= (others => '0');
        D <= to_signed(-128, 44);
        wait for 8 ns;
        
        ---Clear inputs
        A1 <= (others => '0');
        B1 <= (others => '0');
        A2 <= (others => '0');
        B2 <= (others => '0');
        C <= (others => '0');
        D <= (others => '0');
        
        wait;
	end process;
end tb;
