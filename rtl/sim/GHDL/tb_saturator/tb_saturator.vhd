library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity testbench_saturator is
-- empty
end testbench_saturator;

architecture tb of testbench_saturator is

--Device Under Test component
component saturator is port (i_clk, i_sign : in std_logic;
                             i_val : in std_logic_vector(17 downto 0);
                             o_res : out std_logic_vector(7 downto 0)); 
end component; 

signal i_clk, i_sign : std_logic;
signal i_val : std_logic_vector(17 downto 0);
signal o_res : std_logic_vector(7 downto 0);

begin

	--Connect DUT
    DUT: saturator port map (i_clk => i_clk, i_sign => i_sign,
                        i_val => i_val, o_res => o_res);

    clk_process: process
		begin
        i_clk <= '1';
    	wait for 2 ns;
    	i_clk <= '0';
    	wait for 2 ns;
	end process;

    process
    begin
        
        i_sign <= '0';
        i_val <= (others => '0');
        wait for 16 ns;

        i_val <= std_logic_vector(to_signed(2048, 18)); --128 in S Q13.4/ should be fine    
        wait for 2 ns;

        i_val <= std_logic_vector(to_signed(4096, 18)); --256 in S Q13.4/ should be clamped to 255 
        wait for 6 ns;

        i_val <= std_logic_vector(to_signed(8100, 18)); --506.25 in S Q13.4/ should be clamped to 255 
        wait for 4 ns;

        i_sign <= '1';
        i_val <= std_logic_vector(to_signed(-2064, 18)); -- -129 in S Q13.4/ should be clamped to -128    
        wait for 4 ns;

        i_val <= std_logic_vector(to_signed(-1024, 18)); -- -64 in S Q13.4/ should be fine 
        wait for 4 ns;

        i_val <= std_logic_vector(to_signed(1024, 18)); -- 64 in S Q13.4/ should be fine
        wait for 4 ns;

        i_val <= std_logic_vector(to_signed(4096, 18)); -- 256 in S Q13.4/ should be clamped to 127 
        wait for 4 ns;

        ---Clear inputs
        
        wait;
	end process;
end tb;