
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
  
    ------------------------
    -- AXI3 master interface
    ------------------------
    -- write address channel signals
    o_m_awid     : out std_logic_vector(3 downto 0);
    o_m_awaddr   : out std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    o_m_awlen    : out std_logic_vector(3 downto 0);
    o_m_awsize   : out std_logic_vector(2 downto 0);
    o_m_awburst  : out std_logic_vector(1 downto 0);
    o_m_awlock   : out std_logic_vector(1 downto 0);
    o_m_awcache  : out std_logic_vector(3 downto 0);
    o_m_awprot   : out std_logic_vector(2 downto 0);
    o_m_awvalid  : out std_logic;
    i_m_awready  : in  std_logic;
    
    -- write data channel signals
    o_m_wid      : out std_logic_vector(3 downto 0);
    o_m_wdata    : out std_logic_vector(M_DATA_WIDTH-1 downto 0);
    o_m_wstrb    : out std_logic_vector(3 downto 0);
    o_m_wlast    : out std_logic;
    o_m_wvalid   : out std_logic;
    i_m_wready   : in  std_logic;
    
    -- write response channel signals
    i_m_bid      : in  std_logic_vector(3 downto 0);
    i_m_bresp    : in  std_logic_vector(1 downto 0);
    i_m_bvalid   : in  std_logic;
    o_m_bready   : out std_logic;
    
    -- read address channel signals
    o_m_arid     : out std_logic_vector(3 downto 0);
    o_m_araddr   : out std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    o_m_arlen    : out std_logic_vector(3 downto 0);
    o_m_arsize   : out std_logic_vector(2 downto 0);
    o_m_arburst  : out std_logic_vector(1 downto 0);
    o_m_arlock   : out std_logic_vector(1 downto 0);
    o_m_arcache  : out std_logic_vector(3 downto 0);
    o_m_arprot   : out std_logic_vector(2 downto 0);
    o_m_arvalid  : out std_logic;
    i_m_arready  : in  std_logic;
    
    -- read data channel signals
    i_m_rid      : in  std_logic_vector(3 downto 0);
    i_m_rdata    : in  std_logic_vector(M_DATA_WIDTH-1 downto 0);
    i_m_rresp    : in  std_logic_vector(1 downto 0);
    i_m_rlast    : in  std_logic;
    i_m_rvalid   : in  std_logic;
    o_m_rready   : out std_logic;
    
    -----------------------
    -- AXI3 slave interface
    -----------------------
    -- write address channel signals
    i_s_awid     : in  std_logic_vector(3 downto 0);
    i_s_awaddr   : in  std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    i_s_awlen    : in  std_logic_vector(3 downto 0);
    i_s_awsize   : in  std_logic_vector(2 downto 0);
    i_s_awburst  : in  std_logic_vector(1 downto 0);
    i_s_awlock   : in  std_logic_vector(1 downto 0);
    i_s_awcache  : in  std_logic_vector(3 downto 0);
    i_s_awprot   : in  std_logic_vector(2 downto 0);
    i_s_awvalid  : in  std_logic;
    o_s_awready  : out std_logic;
    
    -- write data channel signals
    i_s_wid      : in  std_logic_vector(3 downto 0);
    i_s_wdata    : in  std_logic_vector(M_DATA_WIDTH-1 downto 0);
    i_s_wstrb    : in  std_logic_vector(3 downto 0);
    i_s_wlast    : in  std_logic;
    i_s_wvalid   : in  std_logic;
    o_s_wready   : out std_logic;
    
    -- write response channel signals
    o_m_bid      : out std_logic_vector(3 downto 0);
    o_m_bresp    : out std_logic_vector(1 downto 0);
    o_m_bvalid   : out std_logic;
    i_m_bready   : in  std_logic;
    
    -- read address channel signals
    i_s_arid     : in  std_logic_vector(3 downto 0);
    i_s_araddr   : in  std_logic_vector(M_ADDR_WIDTH-1 downto 0);
    i_s_arlen    : in  std_logic_vector(3 downto 0);
    i_s_arsize   : in  std_logic_vector(2 downto 0);
    i_s_arburst  : in  std_logic_vector(1 downto 0);
    i_s_arlock   : in  std_logic_vector(1 downto 0);
    i_s_arcache  : in  std_logic_vector(3 downto 0);
    i_s_arprot   : in  std_logic_vector(2 downto 0);
    i_s_arvalid  : in  std_logic;
    o_s_arready  : out std_logic;
    
    -- read data channel signals
    o_s_rid      : out std_logic_vector(3 downto 0);
    o_s_rdata    : out std_logic_vector(M_DATA_WIDTH-1 downto 0);
    o_s_rresp    : out std_logic_vector(1 downto 0);
    o_s_rlast    : out std_logic;
    o_s_rvalid   : out std_logic;
    i_s_rready   : in  std_logic;
    
    -----------------------------------------
    -- APB slave interface (register package)
    -----------------------------------------
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
