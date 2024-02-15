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
		i_zero,i_one: in STD_LOGIC_VECTOR (7 downto 0);
		o_pixel: out STD_LOGIC_VECTOR (7 downto 0));
end component;

-- D flip-flop declaration
component cluster_feeder_flipflop is
    port(clk: in std_logic;
        i_pixel: in std_logic_vector (7 downto 0);
        o_pixel: out std_logic_vector (7 downto 0));
end component;

-- signal for shift register outputs in serializing pipeline
signal shiftreg_7_out, shiftreg_6_out, shiftreg_5_out,
shiftreg_4_out, shiftreg_3_out,shiftreg_2_out,
shiftreg_1_out, shiftreg_0_out: std_logic_vector (7 downto 0);

-- signal for mux outputs in the serializing pipeline
signal shiftreg_mux7_out, shiftreg_mux6_out, shiftreg_mux5_out,
shiftreg_mux4_out, shiftreg_mux3_out, shiftreg_mux2_out,
shiftreg_mux1_out: std_logic_vector (7 downto 0);

-- singal for the select mux outputs interfacing the serializing pipeline
signal pipeline_sel_mux0_out, pipeline_sel_mux1_out,
pipeline_sel_mux2_out: std_logic_vector (7 downto 0);

-- signal for output of the mux of the pixel shifter
signal i_ser_mux1, i_ser_mux2, i_ser_mux3,
i_ser_mux4: std_logic_vector(7 downto 0);

signal i_sel_intl, i_new_intl: std_logic; 


begin

    i_sel_intl <= i_sel AND i_new;
    i_new_intl <= (i_sel NAND i_new) and i_new;
    -- 3 select mux to for pipelining the last 3 pixels before serializing pipeline
    -- pipeline_sel_mux0: cluster_feeder_mux
    -- port map(sel =>i_sel_intl, clk => i_clk, i_zero => i_pixel_0, i_one => i_pixel_5, o_pixel => pipeline_sel_mux0_out);
    -- pipeline_sel_mux1: cluster_feeder_mux
    -- port map(sel =>i_sel_intl, clk => i_clk, i_zero => i_pixel_1, i_one => i_pixel_6, o_pixel => pipeline_sel_mux1_out);
    -- pipeline_sel_mux2: cluster_feeder_mux
    -- port map(sel =>i_sel_intl, clk => i_clk, i_zero => i_pixel_2, i_one => i_pixel_7, o_pixel => pipeline_sel_mux2_out);

pipeline_sel_mux0_out <= i_pixel_5 when i_sel_intl = '1' else
                        i_pixel_0 when i_new = '1';
pipeline_sel_mux1_out <= i_pixel_6 when i_sel_intl = '1' else
                        i_pixel_1 when i_new = '1';
pipeline_sel_mux2_out <= i_pixel_7 when i_sel_intl = '1' else
                        i_pixel_2 when i_new = '1';

    -- Serializing Pipeline
    shiftreg7: cluster_feeder_flipflop
    port map(clk =>i_clk, i_pixel => i_pixel_7, o_pixel => shiftreg_7_out);
    shiftreg_mux7: cluster_feeder_mux
    port map(sel=>i_new_intl, clk => i_clk, i_zero => shiftreg_7_out, i_one => i_pixel_6, o_pixel => shiftreg_mux7_out);
    
    -- shiftreg6: cluster_feeder_flipflop
    -- port map(clk =>i_clk, i_pixel => shiftreg_mux7_out, o_pixel => shiftreg_6_out);
    shiftreg_mux6: cluster_feeder_mux
    port map(sel=>i_new_intl, clk => i_clk, i_zero => shiftreg_mux7_out, i_one => i_pixel_5, o_pixel => shiftreg_mux6_out);

    -- shiftreg5: cluster_feeder_flipflop
    -- port map(clk =>i_clk, i_pixel => shiftreg_mux6_out, o_pixel => shiftreg_5_out);
    shiftreg_mux5: cluster_feeder_mux
    port map(sel=>i_new_intl, clk => i_clk, i_zero => shiftreg_5_out, i_one => i_pixel_4, o_pixel => shiftreg_mux5_out);

    -- shiftreg4: cluster_feeder_flipflop
    -- port map(clk =>i_clk, i_pixel => shiftreg_mux5_out, o_pixel => shiftreg_4_out);
    shiftreg_mux4: cluster_feeder_mux
    port map(sel=>i_new_intl, clk => i_clk, i_zero => shiftreg_mux5_out, i_one => i_pixel_3, o_pixel => shiftreg_mux4_out);

    -- shiftreg3: cluster_feeder_flipflop
    -- port map(clk =>i_clk, i_pixel => shiftreg_mux4_out, o_pixel => shiftreg_3_out);
    shiftreg_mux3: cluster_feeder_mux
    port map(sel=>i_new, clk => i_clk, i_zero => shiftreg_mux4_out, i_one => pipeline_sel_mux2_out, o_pixel => shiftreg_mux3_out);
    
    -- shiftreg2: cluster_feeder_flipflop
    -- port map(clk =>i_clk, i_pixel => shiftreg_mux3_out, o_pixel => shiftreg_2_out);
    -- shiftreg_mux2: cluster_feeder_mux
    -- port map(sel=>i_new, clk => i_clk, i_zero => shiftreg_2_out, i_one => pipeline_sel_mux1_out, o_pixel => shiftreg_mux2_out);

    -- shiftreg1: cluster_feeder_flipflop
    -- port map(clk =>i_clk, i_pixel => shiftreg_mux2_out, o_pixel => shiftreg_1_out);
    -- shiftreg_mux1: cluster_feeder_mux
    -- port map(sel=>i_new, clk => i_clk, i_zero => shiftreg_1_out, i_one => pipeline_sel_mux0_out, o_pixel => shiftreg_mux1_out);

    shiftreg_mux2: cluster_feeder_mux
    port map(sel=> i_new, clk=> i_clk, i_zero=>shiftreg_mux3_out, i_one =>pipeline_sel_mux1_out, o_pixel => shiftreg_mux2_out);

    shiftreg_mux1: cluster_feeder_mux
    port map(sel=>i_new, clk=>i_clk, i_zero =>shiftreg_mux2_out, i_one=>pipeline_sel_mux0_out, o_pixel=>shiftreg_mux1_out);
    
    --shiftreg0: cluster_feeder_flipflop
    --port map(clk =>i_clk, i_pixel => shiftreg_mux1_out, o_pixel => shiftreg_0_out);
    
    --Pixel Shifter Mux Instantiation
    ser_mux0: cluster_feeder_mux
    port map(sel => i_sel_intl, clk => i_clk, i_zero=>shiftreg_mux1_out, i_one => i_pixel_4, o_pixel => i_ser_mux1);
    
    ser_mux1: cluster_feeder_mux
    port map(sel => i_sel_intl, clk => i_clk, i_zero=>i_ser_mux1, i_one => i_pixel_3, o_pixel => i_ser_mux2);
    
    ser_mux2: cluster_feeder_mux
    port map(sel => i_sel_intl, clk => i_clk, i_zero=>i_ser_mux2, i_one => i_pixel_2, o_pixel => i_ser_mux3);

    ser_mux3: cluster_feeder_mux
    port map(sel => i_sel_intl, clk => i_clk, i_zero=>i_ser_mux3, i_one => i_pixel_1, o_pixel => i_ser_mux4);

    ser_mux4: cluster_feeder_mux
    port map(sel => i_sel_intl, clk => i_clk, i_zero=>i_ser_mux4, i_one => i_pixel_0, o_pixel => o_pixel_0);

   o_pixel_1 <= i_ser_mux4;
   o_pixel_2 <= i_ser_mux3;
   o_pixel_3 <= i_ser_mux2;
   o_pixel_4 <= i_ser_mux1;


end Behavioral;