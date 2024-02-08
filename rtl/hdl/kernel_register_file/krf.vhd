library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




entity krf is port ( i_clk, i_rst, i_valid : in std_logic;
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
    signal reg_0, reg_1, reg_2, reg_3, reg_4 : std_logic_vector(39 downto 0);

    signal fsm_clk: std_logic;

    begin

    --using this in the event that a i_rst rising edge occurs at the same time as a clock rising edge:
    --we want to latch the data immediatly, and not at the next clock cycle
    fsm_clk <= i_clk and i_valid and i_rst;

    o_kr_0 <= reg_0;
    o_kr_1 <= reg_1;
    o_kr_2 <= reg_2;
    o_kr_3 <= reg_3;
    o_kr_4 <= reg_4;

    process(fsm_clk, i_rst)
        begin
--TODO: TMR. RTG4_FPGA_Fabric_User_Guide_UG0574_V6, 3.1.2 STMR-D Flip-Flop, USE LIBERO TOOL
            if rising_edge(i_rst) then
                krf_fsm_state <= RESET;
            elsif rising_edge(fsm_clk) then
                case (krf_fsm_state) is

                    when RESET =>
                        reg_0 <= i_data(63 downto 24);
                        reg_1(39 downto 16) <= i_data(23 downto 0);
                        krf_fsm_state <= PACK1_LOADED;

                    when PACK1_LOADED =>
                        reg_1(15 downto 0) <= i_data(63 downto 48);
                        reg_2 <= i_data(47 downto 8);                        
                        reg_3(39 downto 32) <= i_data(7 downto 0);
                        krf_fsm_state <= PACK2_LOADED;

                    when PACK2_LOADED =>
                        reg_3(31 downto 0) <= i_data(63 downto 32);
                        reg_4(39 downto 8) <= i_data(31 downto 0);
                        krf_fsm_state <= PACK3_LOADED;


                    when PACK3_LOADED =>
                        reg_4(7 downto 0) <= i_data(63 downto 56);
                        krf_fsm_state <= READY;


                    when READY =>
                        krf_fsm_state <= READY;

                end case;
            end if;            
    end process;
end rtl;