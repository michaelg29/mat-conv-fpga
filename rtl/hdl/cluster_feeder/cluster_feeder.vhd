library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cluster_feeder is
    Port ( i_clk : in STD_LOGIC;
           i_sel : in STD_LOGIC;
           i_new : in STD_LOGIC;
          
           i_pixel_0 : in STD_LOGIC_VECTOR (7 downto 0);
           i_pixel_1 : in STD_LOGIC_VECTOR (7 downto 0);
           i_pixel_2 : in STD_LOGIC_VECTOR (7 downto 0);
           i_pixel_3 : in STD_LOGIC_VECTOR (7 downto 0);
           i_pixel_4 : in STD_LOGIC_VECTOR (7 downto 0);
           i_pixel_5 : in STD_LOGIC_VECTOR (7 downto 0);
           i_pixel_6 : in STD_LOGIC_VECTOR (7 downto 0);
           i_pixel_7 : in STD_LOGIC_VECTOR (7 downto 0);
           
           o_pixel_0 : out STD_LOGIC_VECTOR (7 downto 0);
           o_pixel_1 : out STD_LOGIC_VECTOR (7 downto 0);
           o_pixel_2 : out STD_LOGIC_VECTOR (7 downto 0);
           o_pixel_3 : out STD_LOGIC_VECTOR (7 downto 0);
           o_pixel_4 : out STD_LOGIC_VECTOR (7 downto 0));
           
end cluster_feeder;

architecture Behavioral of cluster_feeder is

-- 2-to-1 Mux declaration
component cluster_feeder_mux is
	port(sel, clk: in std_logic;
		A, B: in STD_LOGIC_VECTOR (7 downto 0);
		o_pixel: out STD_LOGIC_VECTOR (7 downto 0));
end component;

-- D flip-flop declaration
component cluster_feeder_flipflop is
    port(clk: in std_logic;
        i_pixel: in std_logic_vector (7 downto 0);
        o_pixel: out std_logic_vector (7 downto 0));
end component;

signal shiftreg_7_out, shiftreg_6_out, shiftreg_5_out,
shiftreg_4_out, shiftreg_3_out,shiftreg_2_out,
shiftreg_1_out, shiftreg_0_out: std_logic_vector (7 downto 0);

signal shiftreg_mux7_out, shiftreg_mux6_out, shiftreg_mux5_out,
shiftreg_mux4_out, shiftreg_mux3_out, shiftreg_mux2_out,
shiftreg_mux1_out: std_logic_vector (7 downto 0);

signal pipeline_sel_mux0_out, pipeline_sel_mux1_out,
pipeline_sel_mux2_out: std_logic_vector (7 downto 0);

begin

    -- 3 Mux to for pipelining the last 3 pixels before serializing pipeline
    pipeline_sel_mux0: cluster_feeder_mux
    port map(sel =>i_sel, clk => i_clk, A => )

    -- Serializing Pipeline
    shiftreg7: cluster_feeder_flipflop
    port map(clk =>i_clk, i_pixel => i_pixel_7, o_pixel => shiftreg_7_out);
    shiftreg_mux7: cluster_feeder_mux
    port map(sel=>i_new, clk => i_clk, A => i_pixel_6, B => shiftreg_7_out, o_pixel => shiftreg_mux7_out);
    
    shiftreg6: cluster_feeder_flipflop
    port map(clk =>i_clk, i_pixel => shiftreg_mux7_out, o_pixel => shiftreg_6_out);
    shiftreg_mux6: cluster_feeder_mux
    port map(sel=>i_new, clk => i_clk, A => i_pixel_5, B => shiftreg_6_out, o_pixel => shiftreg_mux6_out);


    --Pixel Shifter Mux Instantiation
    


    process(i_clk)
    begin
        if(rising_edge(i_clk)) then
        end if;

    end process;
end Behavioral;