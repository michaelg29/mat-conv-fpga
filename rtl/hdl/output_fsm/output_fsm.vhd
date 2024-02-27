
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- constants package
library mat_conv_pkg_library;
use mat_conv_pkg_library.mat_conv_pkg.all;

-----------------------
-- Output FSM entity --
-----------------------
entity output_fsm is
  generic (
    -- module configuration
    G_NUM_CLUSTERS   : integer := 4; -- number of clusters
    G_CMP_LATENCY    : integer := 7  -- clock cycle latency for cluster computation
  );
  port (
    -- clock and reset interface
    i_macclk         : in  std_logic;
    i_rst_n          : in  std_logic;
    i_por_n          : in  std_logic;

    -- input FSM
    i_cmd_err        : in  std_logic;
    i_cmd_valid      : in  std_logic;
    i_cmd_subj       : in  std_logic;
    i_payload_done   : in  std_logic;
    i_prepad_done    : in  std_logic;

    -- clusters
    i_output_valid   : in  std_logic_vector(G_NUM_CLUSTERS-1 downto 0);

    -- global memory
    i_ack_ar_rvalid  : in  std_logic;
    i_reg_ar1_rvalid : in  std_logic;
    o_accept_reg_cw1 : out std_logic;
    o_ack_ar_addr    : out std_logic_vector(2 downto 0);
    o_ack_ar_ren     : out std_logic;
    o_reg_ar1_ren    : out std_logic;
    o_reg_ar1_addr   : out std_logic;

    -- output FIFO
    i_buf_empty      : in  std_logic;
    o_fifo_accept_w  : out std_logic_vector(1 downto 0);

    -- AXI Transmitter
    o_new_addr       : out std_logic;

    -- global status
    o_output_written : out std_logic;

    -- external interface
    o_mat_conv_int   : out std_logic
  );
end output_fsm;

---------------------------
-- Main RTL architecture --
---------------------------
architecture rtl of output_fsm is

  ----------------------
  -- STATE DEFINITION --
  ----------------------
  type OUTPUT_FSM_STATE_T is (
    FSM_RESTART,
    WAIT_PAYLOAD,
    SET_OUT_ADDR,
    PAYLOAD_TX,
    SET_TX_ADDR,
    ACK_TX
  );
  signal output_fsm_state : OUTPUT_FSM_STATE_T;

begin

  ------------------
  -- Main Process --
  ------------------
  p_main : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_rst_n = '0' or i_por_n = '0') then

      else
        -- calculate new state
        case (output_fsm_state) is

          -- unknown state
          when others =>
            -- go into processing error state

        end case;
      end if;
    end if;
  end process p_main;

end rtl;
