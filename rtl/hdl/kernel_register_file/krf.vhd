library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




entity krf is port ( i_clk, i_rst_n, i_valid : in std_logic;
                      i_data: in std_logic_vector(63 downto 0);
                      o_kr_0, o_kr_1, o_kr_2, o_kr_3, o_kr_4 : out std_logic_vector(39 downto 0)); 
end krf; 

architecture rtl of krf is

    --TODO hamming distance of 3 with state recovery
    type KRF_FSM_STATE_T is (
        RESET,
        PACK1_LOADED,
        PACK2_LOADED,
        PACK3_LOADED,
        READY
    );

    signal krf_fsm_state : KRF_FSM_STATE_T;
    --TODO: TMR. RTG4_FPGA_Fabric_User_Guide_UG0574_V6, 3.1.2 STMR-D Flip-Flop, USE LIBERO TOOL
    signal reg_0, reg_1, reg_2, reg_3, reg_4 : std_logic_vector(39 downto 0);

    begin

    o_kr_0 <= reg_0;
    o_kr_1 <= reg_1;
    o_kr_2 <= reg_2;
    o_kr_3 <= reg_3;
    o_kr_4 <= reg_4;

    process(i_clk, i_rst_n)
        begin
            if rising_edge(i_clk) then

                if (i_rst_n = '0') then
                    krf_fsm_state <= RESET;
                    reg_0 <= (others => '0');
                    reg_1 <= (others => '0');
                    reg_2 <= (others => '0');
                    reg_3 <= (others => '0');
                    reg_4 <= (others => '0'); 

                elsif(i_valid = '1') then
                    case (krf_fsm_state) is

                        when RESET =>
                            reg_0 <= i_data(39 downto 0);
                            reg_1(23 downto 0) <= i_data(63 downto 40);
                            krf_fsm_state <= PACK1_LOADED;

                        when PACK1_LOADED =>

                            reg_1(39 downto 24) <= i_data(15 downto 0);
                            reg_2(39 downto 0) <= i_data(55 downto 16);
                            reg_3(7 downto 0) <= i_data(63 downto 56);
                            krf_fsm_state <= PACK2_LOADED;

                        when PACK2_LOADED =>

                            reg_3(39 downto 8) <= i_data(31 downto 0);
                            reg_4(31 downto 0) <= i_data(63 downto 32);
                            krf_fsm_state <= PACK3_LOADED;


                        when PACK3_LOADED =>
                            reg_4(39 downto 32) <= i_data(7 downto 0);
                            krf_fsm_state <= READY;


                        when READY =>
                            krf_fsm_state <= READY;

                    end case;

                end if;

            end if;        
    end process;
end rtl;