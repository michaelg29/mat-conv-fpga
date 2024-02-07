-----------------------------------------
--2to1 multiplexer structural TestBench--
-----------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity testbench_krf is
-- empty
end testbench_krf;

architecture tb of testbench_krf is

--Device Under Test component
component krf is port (  i_clk, i_rst, i_valid : in std_logic;
                         i_data: in std_logic_vector(63 downto 0);
                         o_kr_0, o_kr_1, o_kr_2, o_kr_3, o_kr_4 : out std_logic_vector(39 downto 0));  
end component; 

signal clk, rst, valid : std_logic;
signal data: std_logic_vector(63 downto 0);
signal kr_0, kr_1, kr_2, kr_3, kr_4 : std_logic_vector(39 downto 0);

begin

	--Connect DUT
    DUT: krf port map ( i_clk => clk, i_rst => rst, i_valid => valid, i_data => data, o_kr_0 => kr_0, o_kr_1 => kr_1, o_kr_2 => kr_2, o_kr_3 => kr_3, o_kr_4 => kr_4);

    clk_process: process
		begin
        clk <= '1';
    	wait for 2 ns;
    	clk <= '0';
    	wait for 2 ns;
	end process;

    process
    begin
    	data <= (others =>'0');
        rst <= '0';
        valid <= '0';
        wait for 8 ns;

        rst <= '1';
        wait for 4 ns;

        valid <= '1';
        data <= x"FF00FF00FF00FF00";
        wait for 4 ns;
        
        data <= x"AABBAABBAABBAABB";
        wait for 4 ns;

        data <= x"1122112211221122";
        wait for 4 ns;

        data <= x"5588888888888888";       
        wait for 1 ns;

        rst <= '0';
        wait for 2 ns;

        rst <= '1';
        wait for 1 ns;


        data <= x"0000000000111111";
        wait for 4 ns;
        
        data <= x"1111222222222233";
        wait for 4 ns;

        data <= x"3333333344444444";
        wait for 4 ns;

        data <= x"44FFFFFFFFFFFFFF";
        wait for 4 ns;

        rst <= '0';
        wait for 4 ns;

        rst <= '1';
        data <= x"FFFFFFFFFFFFFFFF";
        wait for 4 ns;
        
        data <= x"AAAAAAAAAABBBBBB";
        wait for 4 ns;

        data <= x"BBBBCCCCCCCCCCDD";
        wait for 4 ns;

        data <= x"DDDDDDDDEEEEEEEE";
        wait for 4 ns;

        data <= x"EEFFFFFFFFFFFFFF";
        wait for 4 ns;

        wait for 8 ns;
        
        ---Clear inputs
        data <= (others =>'0');
        rst <= '0';
        valid <= '0';
        wait;
	end process;
end tb;
