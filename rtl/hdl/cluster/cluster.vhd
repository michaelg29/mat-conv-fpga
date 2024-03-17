library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cluster is
  port (i_clk, i_new_pkt, i_is_subj, i_is_kern, i_discont, i_newrow, i_cmd_kern_signed: in std_logic; 
        i_pkt : in std_logic_vector(63 downto 0);
        --i_waddr : in std_logic_vector(7 downto 0);
        o_out_rdy: out std_logic;
        o_pixel : out std_logic_vector(7 downto 0));
end cluster;

architecture cluster_arch of cluster is 

    signal krf_valid, valid_rx_pixels, kernel_signed: std_logic;

    signal core_en : std_logic_vector(2 downto 0); --2 cc delay for core_en
    signal out_rdy : std_logic_vector(6 downto 0); --6 cc delay for out_rdy (5 originally + 1 for saturator)

    signal feed_0, feed_1, feed_2, feed_3, feed_4 : std_logic_vector(15 downto 0); -- delay by 1 clock cycle (8 bit times 2)


    signal k_row0, k_row1, k_row2, k_row3, k_row4 : std_logic_vector(39 downto 0);

    signal c0_k0, c0_k1, c0_k2, c0_k3, c0_k4,
            c1_k0, c1_k1, c1_k2, c1_k3, c1_k4,
            c2_k0, c2_k1, c2_k2, c2_k3, c2_k4,
            c3_k0, c3_k1, c3_k2, c3_k3, c3_k4, 
            c4_k0, c4_k1, c4_k2, c4_k3, c4_k4 : std_logic_vector(7 downto 0);


    signal c0_sub, c1_sub, c2_sub, c3_sub, c4_sub, c0_res, c1_res, c2_res, c3_res, c4_res : std_logic_vector(17 downto 0);

    signal pixel_unrounded : std_logic_vector(17 downto 0);

    signal krf_data : std_logic_vector(63 downto 0);

    signal addr_counter : std_logic_vector(10 downto 0);

begin
    krf_data <= i_pkt(63 downto 0);

    krf_valid <= i_new_pkt and not i_is_subj;
    valid_rx_pixels <= i_new_pkt and i_is_subj;

    o_out_rdy<= out_rdy(6);

    c0_k0 <= k_row0(7 downto 0);
    c0_k1 <= k_row0(15 downto 8);
    c0_k2 <= k_row0(23 downto 16);
    c0_k3 <= k_row0(31 downto 24);
    c0_k4 <= k_row0(39 downto 32);

    c1_k0 <= k_row1(7 downto 0);
    c1_k1 <= k_row1(15 downto 8);
    c1_k2 <= k_row1(23 downto 16);
    c1_k3 <= k_row1(31 downto 24);
    c1_k4 <= k_row1(39 downto 32);

    c2_k0 <= k_row2(7 downto 0);
    c2_k1 <= k_row2(15 downto 8);
    c2_k2 <= k_row2(23 downto 16);
    c2_k3 <= k_row2(31 downto 24);
    c2_k4 <= k_row2(39 downto 32);

    c3_k0 <= k_row3(7 downto 0);
    c3_k1 <= k_row3(15 downto 8);
    c3_k2 <= k_row3(23 downto 16);
    c3_k3 <= k_row3(31 downto 24);
    c3_k4 <= k_row3(39 downto 32);

    c4_k0 <= k_row4(7 downto 0);
    c4_k1 <= k_row4(15 downto 8);
    c4_k2 <= k_row4(23 downto 16);
    c4_k3 <= k_row4(31 downto 24);
    c4_k4 <= k_row4(39 downto 32);

    core0: entity work.core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c0_k0, i_k1 => c0_k1, i_k2 => c0_k2, i_k3 => c0_k3, i_k4 => c0_k4, 
                i_s0 => feed_0(15 downto 8), i_s1 => feed_1(15 downto 8), i_s2 => feed_2(15 downto 8), i_s3 => feed_3(15 downto 8), i_s4 => feed_4(15 downto 8), 
                i_sub => c0_sub, o_res => c0_res);

    core1: entity work.core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c1_k0, i_k1 => c1_k1, i_k2 => c1_k2, i_k3 => c1_k3, i_k4 => c1_k4, 
                i_s0 => feed_0(15 downto 8), i_s1 => feed_1(15 downto 8), i_s2 => feed_2(15 downto 8), i_s3 => feed_3(15 downto 8), i_s4 => feed_4(15 downto 8), 
                i_sub => c1_sub, o_res => c1_res);

    core2: entity work.core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c2_k0, i_k1 => c2_k1, i_k2 => c2_k2, i_k3 => c2_k3, i_k4 => c2_k4, 
                i_s0 => feed_0(15 downto 8), i_s1 => feed_1(15 downto 8), i_s2 => feed_2(15 downto 8), i_s3 => feed_3(15 downto 8), i_s4 => feed_4(15 downto 8), 
                i_sub => c2_sub, o_res => c2_res);

    core3: entity work.core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c3_k0, i_k1 => c3_k1, i_k2 => c3_k2, i_k3 => c3_k3, i_k4 => c3_k4, 
                i_s0 => feed_0(15 downto 8), i_s1 => feed_1(15 downto 8), i_s2 => feed_2(15 downto 8), i_s3 => feed_3(15 downto 8), i_s4 => feed_4(15 downto 8), 
                i_sub => c3_sub, o_res => c3_res);


    core4: entity work.core 
    generic map (i_round => (7 => '1', others => '0'))
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c4_k0, i_k1 => c4_k1, i_k2 => c4_k2, i_k3 => c4_k3, i_k4 => c4_k4, 
                i_s0 => feed_0(15 downto 8), i_s1 => feed_1(15 downto 8), i_s2 => feed_2(15 downto 8), i_s3 => feed_3(15 downto 8), i_s4 => feed_4(15 downto 8), 
                i_sub => c4_sub, o_res => c4_res);

    cluster_feeder: entity work.cluster_feeder
    port map(i_clk => i_clk, i_sel => i_discont, i_new => valid_rx_pixels, i_pixel_0 => i_pkt(7 downto 0), 
                i_pixel_1 => i_pkt(15 downto 8), i_pixel_2 => i_pkt(23 downto 16), i_pixel_3 => i_pkt(31 downto 24), i_pixel_4 => i_pkt(39 downto 32), 
                i_pixel_5 => i_pkt(47 downto 40), i_pixel_6 => i_pkt(55 downto 48), i_pixel_7 => i_pkt(63 downto 56), 
                o_pixel_0 => feed_0(7 downto 0), o_pixel_1 => feed_1(7 downto 0), o_pixel_2 => feed_2(7 downto 0), o_pixel_3 => feed_3(7 downto 0), o_pixel_4 => feed_4(7 downto 0));

    krf: entity work.krf 
    port map(i_clk => i_clk, i_rst => i_is_kern, i_valid => krf_valid, i_data => krf_data, o_kr_0 => k_row0, o_kr_1 => k_row1, o_kr_2 => k_row2, o_kr_3 => k_row3, o_kr_4 => k_row4);

    saturator: entity work.saturator
    port map(i_clk => i_clk, i_sign => kernel_signed, i_val => pixel_unrounded, o_res => o_pixel);

    cmc: entity work.cmc
    generic map (ECC_EN => '1')
    port map (i_addr => addr_counter,
          i_core_0 => c0_res, i_core_1 => c1_res, i_core_2 => c2_res, i_core_3 => c3_res, i_core_4 => c4_res,
          o_core_0 => c0_sub, o_core_1 => c1_sub, o_core_2 => c2_sub, o_core_3 => c3_sub, o_core_4 => c4_sub, 
          o_pixel=> pixel_unrounded,
          i_clk => i_clk, i_en => '1', i_val => valid_rx_pixels);



  process(i_clk)
    begin
      if(rising_edge(i_clk)) then

        feed_0(15 downto 8) <= feed_0(7 downto 0);
        feed_1(15 downto 8) <= feed_1(7 downto 0);
        feed_2(15 downto 8) <= feed_2(7 downto 0);
        feed_3(15 downto 8) <= feed_3(7 downto 0);
        feed_4(15 downto 8) <= feed_4(7 downto 0);

        out_rdy(6 downto 1) <= out_rdy(5 downto 0);
        core_en(2 downto 1) <= core_en(1 downto 0); 

        if (valid_rx_pixels = '1') then
          out_rdy(0) <= '1';
          core_en(0) <= '1';   
          addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
          
        end if;

        if(i_newrow = '1') then
          addr_counter <= (others => '0');
        end if;

        if (i_is_kern = '1') then
          kernel_signed <= i_cmd_kern_signed;
        end if;
      end if;
  end process;

end cluster_arch;