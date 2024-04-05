library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--i_clk: clock driving the module
--i_new_pkt : asdserted when valid data is on the i_pkt port 
--i_is_subj : asserted when receiving subject data
--i_is_kern : asserted when receiving kernel data
--i_discont : asserted when received pixels are not contiguous with the ones received before
--i_end_of_row : pulsed when the data is from at the end of a row
--i_cmd_kern_signed : determines the sign of the kernel

--i_pkt: port to receive data
--o_out_rdy: indicates that o_pixel contains valid output data
--o_pixel: output total result

entity cluster is
  port (i_clk, i_rst_n, i_new_pkt, i_is_subj, i_is_kern, i_discont, i_end_of_row, i_cmd_kern_signed: in std_logic; 
        i_pkt : in std_logic_vector(63 downto 0);
        i_waddr : in std_logic_vector(7 downto 0);
        o_out_rdy: out std_logic;
        o_pixel : out std_logic_vector(7 downto 0));
end cluster;

architecture cluster_arch of cluster is 

  component cmc is
    generic(
      ECC_EN: integer := 0
    ); 
    port(i_addr: in std_logic_vector(10 downto 0);
        i_core_0, i_core_1, i_core_2,i_core_3, i_core_4: in std_logic_vector(17 downto 0);
        o_core_0, o_core_1, o_core_2,o_core_3, o_core_4, o_pixel: out std_logic_vector(17 downto 0);
        i_clk, i_en: in std_logic;
        i_val: in std_logic
        );
  end component;


  component saturator is port (i_clk, i_sign : in std_logic;
      i_val : in std_logic_vector(17 downto 0);
      o_res : out std_logic_vector(7 downto 0)); 
  end component; 


  component krf is port ( i_clk, i_rst_n, i_valid : in std_logic;
    i_data: in std_logic_vector(63 downto 0);
    o_kr_0, o_kr_1, o_kr_2, o_kr_3, o_kr_4 : out std_logic_vector(39 downto 0)); 
  end component; 


  component core is 
  generic (i_round : signed(43 downto 0) := (2 => '1', others => '0'));
  port ( i_clk, i_en : in std_logic;
          i_k0, i_k1, i_k2, i_k3, i_k4, i_s0, i_s1, i_s2, i_s3, i_s4 : in std_logic_vector(7 downto 0); 
          i_sub: in std_logic_vector(17 downto 0);
          o_res: out std_logic_vector(17 downto 0)); 
  end component; 

  component cluster_feeder is
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
           
  end component;

    --krf_valid: valid kernel data
    --valid_rx_pixels: valid subject data 
    --kernel_signed: 1->kernel values are signed, 0->kernel values are unsigned
    signal krf_valid, valid_rx_pixels, kernel_signed, cluster_feeder_load: std_logic;

    signal core_en : std_logic_vector(2 downto 0); --enables core, with 2 cc delay
    signal out_rdy : std_logic_vector(6 downto 0); --indicates output pixel is valid, with 6 cc delay (5 originally + 1 for saturator)

    signal feed_0, feed_1, feed_2, feed_3, feed_4 : std_logic_vector(23 downto 0); -- connects cluster feeder and cores, delayed by 1 clock cycle (8 bit times 2)


    signal k_row0, k_row1, k_row2, k_row3, k_row4 : std_logic_vector(39 downto 0); --output of KRF

    signal c0_k0, c0_k1, c0_k2, c0_k3, c0_k4,
            c1_k0, c1_k1, c1_k2, c1_k3, c1_k4,
            c2_k0, c2_k1, c2_k2, c2_k3, c2_k4,
            c3_k0, c3_k1, c3_k2, c3_k3, c3_k4, 
            c4_k0, c4_k1, c4_k2, c4_k3, c4_k4 : std_logic_vector(7 downto 0);--connects KRF to cores


    signal c0_sub, c1_sub, c2_sub, c3_sub, c4_sub, c0_res, c1_res, c2_res, c3_res, c4_res : std_logic_vector(17 downto 0);--connects cores to CMC

    signal pixel_unrounded : std_logic_vector(17 downto 0);--connects cmc final output to saturator

    signal krf_data : std_logic_vector(63 downto 0);--input to krf

    signal addr_counter : std_logic_vector(10 downto 0) := (others => '0');--address counter for CMC

    signal valid_counter : std_logic_vector(2 downto 0) := (others => '0'); --Hold internal valid pixels counter

begin
    krf_data <= i_pkt(63 downto 0);

    krf_valid       <= i_new_pkt and i_is_kern and not(i_waddr(7)) and not i_is_subj;
    valid_rx_pixels <= (i_new_pkt and i_is_subj and not(i_waddr(7))) or (valid_counter(0) or valid_counter(1) or valid_counter(2));
    cluster_feeder_load <= (i_new_pkt and i_is_subj and not(i_waddr(7)));

    --This process holds the valid_rx_pixels to hold the CMC i_val as long as the cluster feeder is shifting pixels
    valid_rx_hold : process(i_clk)
    begin
      if(rising_edge(i_clk)) then
        if((i_new_pkt and i_is_subj and not(i_waddr(7))) = '1') then --internal signal valid state counter is reset
          valid_counter <= (others => '1');
        else --internal signal is 
          valid_counter(2 downto 1) <= valid_counter(1) & '0';
        end if;
      end if;
    end process valid_rx_hold;

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

    core0: core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c0_k0, i_k1 => c0_k1, i_k2 => c0_k2, i_k3 => c0_k3, i_k4 => c0_k4, 
                i_s0 => feed_0(23 downto 16), i_s1 => feed_1(23 downto 16), i_s2 => feed_2(23 downto 16), i_s3 => feed_3(23 downto 16), i_s4 => feed_4(23 downto 16), 
                i_sub => c0_sub, o_res => c0_res);

    core1: core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c1_k0, i_k1 => c1_k1, i_k2 => c1_k2, i_k3 => c1_k3, i_k4 => c1_k4, 
                i_s0 => feed_0(23 downto 16), i_s1 => feed_1(23 downto 16), i_s2 => feed_2(23 downto 16), i_s3 => feed_3(23 downto 16), i_s4 => feed_4(23 downto 16), 
                i_sub => c1_sub, o_res => c1_res);

    core2: core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c2_k0, i_k1 => c2_k1, i_k2 => c2_k2, i_k3 => c2_k3, i_k4 => c2_k4, 
                i_s0 => feed_0(23 downto 16), i_s1 => feed_1(23 downto 16), i_s2 => feed_2(23 downto 16), i_s3 => feed_3(23 downto 16), i_s4 => feed_4(23 downto 16), 
                i_sub => c2_sub, o_res => c2_res);

    core3: core 
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c3_k0, i_k1 => c3_k1, i_k2 => c3_k2, i_k3 => c3_k3, i_k4 => c3_k4, 
                i_s0 => feed_0(23 downto 16), i_s1 => feed_1(23 downto 16), i_s2 => feed_2(23 downto 16), i_s3 => feed_3(23 downto 16), i_s4 => feed_4(23 downto 16), 
                i_sub => c3_sub, o_res => c3_res);


    core4: core 
    generic map (i_round => (7 => '1', others => '0'))
    port map (i_clk => i_clk, i_en => core_en(2),
                i_k0 => c4_k0, i_k1 => c4_k1, i_k2 => c4_k2, i_k3 => c4_k3, i_k4 => c4_k4, 
                i_s0 => feed_0(23 downto 16), i_s1 => feed_1(23 downto 16), i_s2 => feed_2(23 downto 16), i_s3 => feed_3(23 downto 16), i_s4 => feed_4(23 downto 16), 
                i_sub => c4_sub, o_res => c4_res);

    cluster_feed: cluster_feeder
    port map(i_clk => i_clk, i_sel => i_discont, i_new => cluster_feeder_load, i_pixel_0 => i_pkt(7 downto 0), 
                i_pixel_1 => i_pkt(15 downto 8), i_pixel_2 => i_pkt(23 downto 16), i_pixel_3 => i_pkt(31 downto 24), i_pixel_4 => i_pkt(39 downto 32), 
                i_pixel_5 => i_pkt(47 downto 40), i_pixel_6 => i_pkt(55 downto 48), i_pixel_7 => i_pkt(63 downto 56), 
                o_pixel_0 => feed_0(7 downto 0), o_pixel_1 => feed_1(7 downto 0), o_pixel_2 => feed_2(7 downto 0), o_pixel_3 => feed_3(7 downto 0), o_pixel_4 => feed_4(7 downto 0));

    kernel_rf: krf 
    port map(i_clk => i_clk, i_rst_n => i_rst_n, i_valid => krf_valid, i_data => krf_data, o_kr_0 => k_row0, o_kr_1 => k_row1, o_kr_2 => k_row2, o_kr_3 => k_row3, o_kr_4 => k_row4);

    sat: saturator
    port map(i_clk => i_clk, i_sign => kernel_signed, i_val => pixel_unrounded, o_res => o_pixel);

    c_mem_c: cmc
    generic map (ECC_EN => 0)
    port map (i_addr => addr_counter,
          i_core_0 => c0_res, i_core_1 => c1_res, i_core_2 => c2_res, i_core_3 => c3_res, i_core_4 => c4_res,
          o_core_0 => c0_sub, o_core_1 => c1_sub, o_core_2 => c2_sub, o_core_3 => c3_sub, o_core_4 => c4_sub, 
          o_pixel=> pixel_unrounded,
          i_clk => i_clk, i_en => '1', i_val => valid_rx_pixels);



  logic: process(i_clk) -- increments address counter, shifts data in the shift registers for delays, latches sign of kernel
    begin
      if(rising_edge(i_clk)) then

        --Delays
        feed_0(23 downto 8) <= feed_0(15 downto 0);
        feed_1(23 downto 8) <= feed_1(15 downto 0);
        feed_2(23 downto 8) <= feed_2(15 downto 0);
        feed_3(23 downto 8) <= feed_3(15 downto 0);
        feed_4(23 downto 8) <= feed_4(15 downto 0);

        out_rdy(6 downto 1) <= out_rdy(5 downto 0);
        core_en(2 downto 1) <= core_en(1 downto 0); 

        if ((i_new_pkt and not(i_waddr(7)) and i_is_subj) = '1') then
          out_rdy(0) <= '1';
          core_en(0) <= '1';   
          addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
        else
          out_rdy(0) <= '0';
          core_en(0) <= '1'; --always enabled 
          
          if (valid_counter(0) or valid_counter(1) or valid_counter(2)) = '1' then          
            addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
          end if;
        end if;

        if(i_end_of_row = '1') then
          addr_counter <= (others => '0');
        end if;

        if (i_is_kern = '1') then
          kernel_signed <= i_cmd_kern_signed;
        end if;
      end if;
  end process;

end cluster_arch;