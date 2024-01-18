
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- register package
library mat_mult_reg_library;

-- top-level entity
-- designed to multiply square matrices (with power-of-2 dimensions) with a maximum dimension of 1024x1024
entity mat_mult_top is
  generic (
    M_ADDR_WIDTH : integer := 64;
    M_DATA_WIDTH : integer := 64;
    S_ADDR_WIDTH : integer := 64;
    S_DATA_WIDTH : integer := 64;
  );
  port (
    --------------------------------
    -- AXI3 interface global signals
    --------------------------------
    i_aclk       : in  std_logic;
    i_arst_n     : in  std_logic;
  
    -----------------------------
    -- AXI3 transmitter interface
    -----------------------------
    -- write address channel signals
    o_tx_awid     : out std_logic_vector(3 downto 0);
    o_tx_awaddr   : out std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    o_tx_awlen    : out std_logic_vector(3 downto 0);
    o_tx_awsize   : out std_logic_vector(2 downto 0);
    o_tx_awburst  : out std_logic_vector(1 downto 0);
    o_tx_awlock   : out std_logic_vector(1 downto 0);
    o_tx_awcache  : out std_logic_vector(3 downto 0);
    o_tx_awprot   : out std_logic_vector(2 downto 0);
    o_tx_awvalid  : out std_logic;
    i_tx_awready  : in  std_logic;
    
    -- write data channel signals
    o_tx_wid      : out std_logic_vector(3 downto 0);
    o_tx_wdata    : out std_logic_vector(M_DATA_WIDTH-1 downto 0);
    o_tx_wstrb    : out std_logic_vector(3 downto 0);
    o_tx_wlast    : out std_logic;
    o_tx_wvalid   : out std_logic;
    i_tx_wready   : in  std_logic;
    
    -- write response channel signals
    i_tx_bid      : in  std_logic_vector(3 downto 0);
    i_tx_bresp    : in  std_logic_vector(1 downto 0);
    i_tx_bvalid   : in  std_logic;
    o_tx_bready   : out std_logic;
    
    -- read address channel signals
    o_tx_arid     : out std_logic_vector(3 downto 0);
    o_tx_araddr   : out std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    o_tx_arlen    : out std_logic_vector(3 downto 0);
    o_tx_arsize   : out std_logic_vector(2 downto 0);
    o_tx_arburst  : out std_logic_vector(1 downto 0);
    o_tx_arlock   : out std_logic_vector(1 downto 0);
    o_tx_arcache  : out std_logic_vector(3 downto 0);
    o_tx_arprot   : out std_logic_vector(2 downto 0);
    o_tx_arvalid  : out std_logic;
    i_tx_arready  : in  std_logic;
    
    -- read data channel signals
    i_tx_rid      : in  std_logic_vector(3 downto 0);
    i_tx_rdata    : in  std_logic_vector(M_DATA_WIDTH-1 downto 0);
    i_tx_rresp    : in  std_logic_vector(1 downto 0);
    i_tx_rlast    : in  std_logic;
    i_tx_rvalid   : in  std_logic;
    o_tx_rready   : out std_logic;
    
    --------------------------
    -- AXI3 receiver interface
    --------------------------
    -- write address channel signals
    i_rx_awid     : in  std_logic_vector(3 downto 0);
    i_rx_awaddr   : in  std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    i_rx_awlen    : in  std_logic_vector(3 downto 0);
    i_rx_awsize   : in  std_logic_vector(2 downto 0);
    i_rx_awburst  : in  std_logic_vector(1 downto 0);
    i_rx_awlock   : in  std_logic_vector(1 downto 0);
    i_rx_awcache  : in  std_logic_vector(3 downto 0);
    i_rx_awprot   : in  std_logic_vector(2 downto 0);
    i_rx_awvalid  : in  std_logic;
    o_rx_awready  : out std_logic;
    
    -- write data channel signals
    i_rx_wid      : in  std_logic_vector(3 downto 0);
    i_rx_wdata    : in  std_logic_vector(M_DATA_WIDTH-1 downto 0);
    i_rx_wstrb    : in  std_logic_vector(3 downto 0);
    i_rx_wlast    : in  std_logic;
    i_rx_wvalid   : in  std_logic;
    o_rx_wready   : out std_logic;
    
    -- write response channel signals
    o_rx_bid      : out std_logic_vector(3 downto 0);
    o_rx_bresp    : out std_logic_vector(1 downto 0);
    o_rx_bvalid   : out std_logic;
    i_rx_bready   : in  std_logic;
    
    -- read address channel signals
    i_rx_arid     : in  std_logic_vector(3 downto 0);
    i_rx_araddr   : in  std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    i_rx_arlen    : in  std_logic_vector(3 downto 0);
    i_rx_arsize   : in  std_logic_vector(2 downto 0);
    i_rx_arburst  : in  std_logic_vector(1 downto 0);
    i_rx_arlock   : in  std_logic_vector(1 downto 0);
    i_rx_arcache  : in  std_logic_vector(3 downto 0);
    i_rx_arprot   : in  std_logic_vector(2 downto 0);
    i_rx_arvalid  : in  std_logic;
    o_rx_arready  : out std_logic;
    
    -- read data channel signals
    o_rx_rid      : out std_logic_vector(3 downto 0);
    o_rx_rdata    : out std_logic_vector(M_DATA_WIDTH-1 downto 0);
    o_rx_rresp    : out std_logic_vector(1 downto 0);
    o_rx_rlast    : out std_logic;
    o_rx_rvalid   : out std_logic;
    i_rx_rready   : in  std_logic;
    
    --------------------------------------------
    -- APB receiver interface (register package)
    --------------------------------------------
    i_pclk       : in  std_logic;
    i_prst_n     : in  std_logic;
    i_regs_sw2hw : in  mat_mult_reg_pkg.regs_sw2hw_t;
    o_regs_hw2sw : out mat_mult_reg_pkg.regs_hw2sw_t;
    i_regs_evnt  : in  mat_mult_reg_pkg.regs_evnt_t;
    o_regs_resp  : out mat_mult_reg_pkg.regs_resp_t;
    
    -----------------------
    -- MAC math block clock
    -----------------------
    i_macclk     : in  std_logic
  );
end mat_mult_top;

architecture rtl of mat_mult_top is

begin

end rtl;
