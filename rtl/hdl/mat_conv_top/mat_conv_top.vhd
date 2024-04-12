
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- submodules
library axi_library;
use axi_library.all;
library input_fsm_library;
use input_fsm_library.all;

-- top-level entity
-- Module to convolve a matrix (max 2^11-1 * 2^11-1) with a square kernel matrix (max 5x5).
entity mat_conv_top is
  generic (
    -- latency measures
    G_MEM_RD_LATENCY       : integer := 2;
    G_CLUSTER_CMPT_LATENCY : integer := 7;

    -- bus widths
    G_TX_ADDR_WIDTH : integer := 32;
    G_TX_DATA_WIDTH : integer := 64;
    G_RX_ADDR_WIDTH : integer := 32;
    G_RX_DATA_WIDTH : integer := 64
  );
  port (
    -------------------
    -- Global interface
    -------------------
    i_macclk      : in  std_logic;
    i_por_n       : in  std_logic;
    o_mc_int      : out std_logic;

    --------------------------------
    -- AXI3 interface global signals
    --------------------------------
    i_aclk        : in  std_logic;
    i_arst_n      : in  std_logic;

    -----------------------------
    -- AXI3 transmitter interface
    -----------------------------
    -- write address channel signals
    o_tx_awid     : out std_logic_vector(3 downto 0);
    o_tx_awaddr   : out std_logic_vector(G_TX_ADDR_WIDTH-1 downto 0);
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
    o_tx_wdata    : out std_logic_vector(G_TX_DATA_WIDTH-1 downto 0);
    o_tx_wstrb    : out std_logic_vector(G_TX_DATA_WIDTH/8-1 downto 0);
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
    o_tx_araddr   : out std_logic_vector(G_TX_ADDR_WIDTH-1 downto 0);
    o_tx_arlen    : out std_logic_vector(3 downto 0);
    o_tx_arsize   : out std_logic_vector(2 downto 0);
    o_tx_arburst  : out std_logic_vector(1 downto 0);
    o_tx_arlock   : out std_logic_vector(1 downto 0);
    o_tx_arcache  : out std_logic_vector(3 downto 0);
    o_tx_arprot   : out std_logic_vector(2 downto 0);
    o_tx_arvalid  : out std_logic;
    i_tx_arready  : in  std_logic;

    -- read data channel signals
    i_tx_rid     : in  std_logic_vector(3 downto 0);
    i_tx_rdata   : in  std_logic_vector(G_TX_DATA_WIDTH-1 downto 0);
    i_tx_rresp   : in  std_logic_vector(1 downto 0);
    i_tx_rlast   : in  std_logic;
    i_tx_rvalid  : in  std_logic;
    o_tx_rready  : out std_logic;

    --------------------------
    -- AXI3 receiver interface
    --------------------------
    -- write address channel signals
    i_rx_awid    : in  std_logic_vector(3 downto 0);
    i_rx_awaddr  : in  std_logic_vector(G_RX_ADDR_WIDTH-1 downto 0);
    i_rx_awlen   : in  std_logic_vector(3 downto 0);
    i_rx_awsize  : in  std_logic_vector(2 downto 0);
    i_rx_awburst : in  std_logic_vector(1 downto 0);
    i_rx_awlock  : in  std_logic_vector(1 downto 0);
    i_rx_awcache : in  std_logic_vector(3 downto 0);
    i_rx_awprot  : in  std_logic_vector(2 downto 0);
    i_rx_awvalid : in  std_logic;
    o_rx_awready : out std_logic;

    -- write data channel signals
    i_rx_wid     : in  std_logic_vector(3 downto 0);
    i_rx_wdata   : in  std_logic_vector(G_RX_DATA_WIDTH-1 downto 0);
    i_rx_wstrb   : in  std_logic_vector(G_RX_DATA_WIDTH/8-1 downto 0);
    i_rx_wlast   : in  std_logic;
    i_rx_wvalid  : in  std_logic;
    o_rx_wready  : out std_logic;

    -- write response channel signals
    o_rx_bid     : out std_logic_vector(3 downto 0);
    o_rx_bresp   : out std_logic_vector(1 downto 0);
    o_rx_bvalid  : out std_logic;
    i_rx_bready  : in  std_logic;

    -- read address channel signals
    i_rx_arid    : in  std_logic_vector(3 downto 0);
    i_rx_araddr  : in  std_logic_vector(G_RX_ADDR_WIDTH-1 downto 0);
    i_rx_arlen   : in  std_logic_vector(3 downto 0);
    i_rx_arsize  : in  std_logic_vector(2 downto 0);
    i_rx_arburst : in  std_logic_vector(1 downto 0);
    i_rx_arlock  : in  std_logic_vector(1 downto 0);
    i_rx_arcache : in  std_logic_vector(3 downto 0);
    i_rx_arprot  : in  std_logic_vector(2 downto 0);
    i_rx_arvalid : in  std_logic;
    o_rx_arready : out std_logic;

    -- read data channel signals
    o_rx_rid     : out std_logic_vector(3 downto 0);
    o_rx_rdata   : out std_logic_vector(G_RX_DATA_WIDTH-1 downto 0);
    o_rx_rresp   : out std_logic_vector(1 downto 0);
    o_rx_rlast   : out std_logic;
    o_rx_rvalid  : out std_logic;
    i_rx_rready  : in  std_logic;

    -------------------------
    -- APB receiver interface
    -------------------------
    i_pclk       : in  std_logic;
    i_prst_n     : in  std_logic;
    i_paddr      : in  std_logic_vector(31 downto 0);
    i_psel       : in  std_logic;
    i_penable    : in  std_logic;
    i_pwrite     : in  std_logic;
    i_pwdata     : in  std_logic_vector(31 downto 0);
    o_pready     : out std_logic;
    o_prdata     : out std_logic_vector(31 downto 0);
    o_pslverr    : out std_logic
  );
end mat_conv_top;

architecture rtl of mat_conv_top is

  -------------------------------
  -- internal component templates
  -------------------------------

  component rx_buffer is
    generic (
      -- FIFO capacity
      NWORDS           : integer range 16 to 512 := 16;
      AWIDTH           : integer range  4 to  10 := 4;
      AEVAL            : integer range  3 to 510 := 4;
      AFVAL            : integer range  3 to 510 := 14;

      -- packet widths
      G_DATA_PKT_WIDTH : integer := 64; -- width of an AXI data packet
      G_ADDR_PKT_WIDTH : integer := 8   -- required relative address size
    );
    port (

      -- clock and reset interface
      i_macclk              : in  std_logic;
      i_aclk                : in  std_logic;
      i_arst_n              : in  std_logic;
      o_rst_n               : out std_logic;

      -- AXI write address channel
      i_rx_axi_awid         : in  std_logic_vector(3 downto 0);
      i_rx_axi_awaddr       : in  std_logic_vector(31 downto 0);
      i_rx_axi_awlen        : in  std_logic_vector(3 downto 0);
      i_rx_axi_awsize       : in  std_logic_vector(2 downto 0);
      i_rx_axi_awburst      : in  std_logic_vector(1 downto 0);
      i_rx_axi_awlock       : in  std_logic;
      i_rx_axi_awcache      : in  std_logic_vector(3 downto 0);
      i_rx_axi_awprot       : in  std_logic_vector(2 downto 0);
      i_rx_axi_awvalid      : in  std_logic;
      o_rx_axi_awready      : out std_logic;

      -- AXI write data channel
      i_rx_axi_wdata        : in  std_logic_vector(63 downto 0);
      i_rx_axi_wstrb        : in  std_logic_vector(7 downto 0);
      i_rx_axi_wlast        : in  std_logic;
      i_rx_axi_wvalid       : in  std_logic;
      o_rx_axi_wready       : out std_logic;

      -- AXI write response channel
      o_rx_axi_bid          : out std_logic_vector(3 downto 0);
      o_rx_axi_bresp        : out std_logic_vector(1 downto 0);
      o_rx_axi_bvalid       : out std_logic;
      i_rx_axi_bready       : in  std_logic;

      -- AXI read address channel (unused)
      i_rx_axi_arid         : in  std_logic_vector(3 downto 0);
      i_rx_axi_araddr       : in  std_logic_vector(31 downto 0);
      i_rx_axi_arlen        : in  std_logic_vector(3 downto 0);
      i_rx_axi_arsize       : in  std_logic_vector(2 downto 0);
      i_rx_axi_arburst      : in  std_logic_vector(1 downto 0);
      i_rx_axi_arlock       : in  std_logic;
      i_rx_axi_arcache      : in  std_logic_vector(3 downto 0);
      i_rx_axi_arprot       : in  std_logic_vector(2 downto 0);
      i_rx_axi_arvalid      : in  std_logic;
      o_rx_axi_arready      : out std_logic;

      -- AXI read data channel (unused)
      o_rx_axi_rid          : out std_logic_vector(3 downto 0);
      o_rx_axi_rdata        : out std_logic_vector(63 downto 0);
      o_rx_axi_rresp        : out std_logic_vector(1 downto 0);
      o_rx_axi_rlast        : out std_logic;
      o_rx_axi_rvalid       : out std_logic;
      i_rx_axi_rready       : in  std_logic;

      -- input FIFO interface
      i_rx_fifo_read        : in  std_logic;
      o_rx_rvalid           : out std_logic;
      o_rx_data             : out std_logic_vector(G_DATA_PKT_WIDTH-1 downto 0);
      o_rx_addr             : out std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
      o_rx_fifo_e           : out std_logic;
      o_rx_fifo_ae          : out std_logic;
      o_rx_fifo_count       : out std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
      o_rx_fifo_oflow       : out std_logic;
      o_rx_fifo_uflow       : out std_logic;
      o_rx_fifo_db          : out std_logic;
      o_rx_fifo_sb          : out std_logic;

      -- output FIFO interface
      i_tx_fifo_af          : in  std_logic;

      -- interface with internal controller
      i_rx_drop_pkts        : in  std_logic;
      i_write_blank_en      : in  std_logic;
      o_write_blank_ack     : out std_logic
    );
  end component;
  component input_fsm is
    generic (
      -- packet widths
      G_DATA_PKT_WIDTH   : integer := 64; -- width of an AXI data packet
      G_ADDR_PKT_WIDTH   : integer := 8   -- required relative address size
    );
    port (
      -- clock and reset interface
      i_macclk          : in  std_logic;
      i_rst_n           : in  std_logic;
      i_por_n           : in  std_logic;

      -- signals to and from Input FIFO
      i_rx_pkt          : in  std_logic;
      i_rx_addr         : in  std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
      i_rx_data         : in  std_logic_vector(G_DATA_PKT_WIDTH-1 downto 0);

      -- signals to and from AXI Receiver
      i_write_blank_ack : in  std_logic;
      o_write_blank_en  : out std_logic;
      o_drop_pkts       : out std_logic;

      -- signals to and from Command Buffer
      i_rdata           : in  std_logic_vector(31 downto 0);
      i_rvalid          : in  std_logic;
      i_state_reg_pls   : in  std_logic;
      o_addr            : out std_logic_vector( 2 downto 0);
      o_ren             : out std_logic;
      o_wen             : out std_logic;
      o_wdata           : out std_logic_vector(31 downto 0);

      -- global status signals
      i_proc_error      : in  std_logic;
      i_res_written     : in  std_logic;
      o_cmd_valid       : out std_logic;
      o_cmd_err         : out std_logic;
      o_cmd_kern        : out std_logic;
      o_cmd_subj        : out std_logic;
      o_cmd_kern_signed : out std_logic;
      o_eor             : out std_logic;
      o_prepad_done     : out std_logic;
      o_payload_done    : out std_logic
    );
  end component;
  component tx_buffer is
    generic (
      -- FIFO capacity
      NWORDS           : integer range 16 to 512 := 512;
      AWIDTH           : integer range  4 to  10 := 10;
      AEVAL            : integer range  3 to 510 := 4;
      AFVAL            : integer range  3 to 510 := 500;

      -- packet widths
      G_DATA_PKT_WIDTH : integer := 64 -- width of an AXI data packet
    );
    port (

      -- clock and reset interface
      i_macclk            : in  std_logic;
      i_aclk              : in  std_logic;
      i_arst_n            : in  std_logic;

      -- interface with internal controller
      i_accept_w          : in  std_logic_vector(1 downto 0);
      i_base_addr         : in  std_logic_vector(31 downto 0);
      i_new_addr          : in  std_logic;

      -- FIFO interface
      i_w0_wdata          : in  std_logic_vector(31 downto 0);
      i_w0_wen            : in  std_logic;
      i_w1_wdata          : in  std_logic_vector(31 downto 0);
      i_w1_wen            : in  std_logic;
      o_tx_fifo_af        : out std_logic;
      o_tx_fifo_db        : out std_logic;
      o_tx_fifo_sb        : out std_logic;
      o_tx_fifo_oflow     : out std_logic;
      o_tx_fifo_uflow     : out std_logic;

      -- AXI write address channel
      o_tx_axi_awid       : out std_logic_vector(3 downto 0);
      o_tx_axi_awaddr     : out std_logic_vector(31 downto 0);
      o_tx_axi_awlen      : out std_logic_vector(3 downto 0);
      o_tx_axi_awsize     : out std_logic_vector(2 downto 0);
      o_tx_axi_awburst    : out std_logic_vector(1 downto 0);
      o_tx_axi_awlock     : out std_logic;
      o_tx_axi_awcache    : out std_logic_vector(3 downto 0);
      o_tx_axi_awprot     : out std_logic_vector(2 downto 0);
      o_tx_axi_awvalid    : out std_logic;
      i_tx_axi_awready    : in  std_logic;

      -- AXI write data channel
      o_tx_axi_wdata      : out std_logic_vector(63 downto 0);
      o_tx_axi_wstrb      : out std_logic_vector(7 downto 0);
      o_tx_axi_wlast      : out std_logic;
      o_tx_axi_wvalid     : out std_logic;
      i_tx_axi_wready     : in  std_logic;

      -- AXI write response channel
      i_tx_axi_bid        : in  std_logic_vector(3 downto 0);
      i_tx_axi_bresp      : in  std_logic_vector(1 downto 0);
      i_tx_axi_bvalid     : in  std_logic;
      o_tx_axi_bready     : out std_logic;

      -- AXI read address channel (unused)
      o_tx_axi_arid       : out std_logic_vector(3 downto 0);
      o_tx_axi_araddr     : out std_logic_vector(31 downto 0);
      o_tx_axi_arlen      : out std_logic_vector(3 downto 0);
      o_tx_axi_arsize     : out std_logic_vector(2 downto 0);
      o_tx_axi_arburst    : out std_logic_vector(1 downto 0);
      o_tx_axi_arlock     : out std_logic;
      o_tx_axi_arcache    : out std_logic_vector(3 downto 0);
      o_tx_axi_arprot     : out std_logic_vector(2 downto 0);
      o_tx_axi_arvalid    : out std_logic;
      i_tx_axi_arready    : in  std_logic;

      -- AXI read data channel (unused)
      i_tx_axi_rid        : in  std_logic_vector(3 downto 0);
      i_tx_axi_rdata      : in  std_logic_vector(63 downto 0);
      i_tx_axi_rresp      : in  std_logic_vector(1 downto 0);
      i_tx_axi_rlast      : in  std_logic;
      i_tx_axi_rvalid     : in  std_logic;
      o_tx_axi_rready     : out std_logic
    );
  end component;

  -------------------
  -- internal signals
  -------------------

  -- global control signals
  signal rst_n : std_logic;

  -- global status signals
  signal proc_error      : std_logic;
  signal res_written     : std_logic;
  signal cmd_valid       : std_logic;
  signal cmd_err         : std_logic;
  signal cmd_kern        : std_logic;
  signal cmd_subj        : std_logic;
  signal cmd_kern_signed : std_logic;
  signal eor             : std_logic;
  signal prepad_done     : std_logic;
  signal payload_done    : std_logic;

  -- input control signals
  signal rx_rvalid       : std_logic;
  signal rx_data         : std_logic_vector(G_RX_DATA_WIDTH-1 downto 0);
  signal rx_addr         : std_logic_vector(7 downto 0);
  signal rx_drop_pkts    : std_logic;
  signal write_blank_en  : std_logic;
  signal write_blank_ack : std_logic;

  -- output control signals
  signal tx_fifo_af      : std_logic;
  signal tx_accept_w     : std_logic_vector(1 downto 0);
  signal tx_base_addr    : std_logic_vector(31 downto 0);
  signal tx_new_addr     : std_logic;
  signal tx_w0_wdata     : std_logic_vector(31 downto 0);
  signal tx_w0_wen       : std_logic;
  signal tx_w1_wdata     : std_logic_vector(31 downto 0);
  signal tx_w1_wen       : std_logic;

begin

  ---------------------------
  -- Input control submodules
  ---------------------------

  -- AXI Receiver and Input FIFO
  u_rx_buffer : rx_buffer
    generic map (
      NWORDS           => ( 16 ),
      AWIDTH           => ( 4 ),
      AEVAL            => ( 4 ),
      AFVAL            => ( 14 ),
      G_DATA_PKT_WIDTH => ( G_RX_DATA_WIDTH ),
      G_ADDR_PKT_WIDTH => ( 8 )
    )
    port map (
      -- clock and reset interface
      i_macclk          => i_macclk,
      i_aclk            => i_aclk,
      i_arst_n          => i_arst_n,
      o_rst_n           => rst_n,

      -- AXI write address channel
      i_rx_axi_awid     => i_rx_awid,
      i_rx_axi_awaddr   => i_rx_awaddr,
      i_rx_axi_awlen    => i_rx_awlen,
      i_rx_axi_awsize   => i_rx_awsize,
      i_rx_axi_awburst  => i_rx_awburst,
      i_rx_axi_awlock   => i_rx_awlock(0),
      i_rx_axi_awcache  => i_rx_awcache,
      i_rx_axi_awprot   => i_rx_awprot,
      i_rx_axi_awvalid  => i_rx_awvalid,
      o_rx_axi_awready  => o_rx_awready,

      -- AXI write data channel
      i_rx_axi_wdata    => i_rx_wdata,
      i_rx_axi_wstrb    => i_rx_wstrb,
      i_rx_axi_wlast    => i_rx_wlast,
      i_rx_axi_wvalid   => i_rx_wvalid,
      o_rx_axi_wready   => o_rx_wready,

      -- AXI write response channel
      o_rx_axi_bid      => o_rx_bid,
      o_rx_axi_bresp    => o_rx_bresp,
      o_rx_axi_bvalid   => o_rx_bvalid,
      i_rx_axi_bready   => i_rx_bready,

      -- AXI read address channel (unused)
      i_rx_axi_arid     => (others => '0'),
      i_rx_axi_araddr   => (others => '0'),
      i_rx_axi_arlen    => (others => '0'),
      i_rx_axi_arsize   => (others => '0'),
      i_rx_axi_arburst  => (others => '0'),
      i_rx_axi_arlock   => '0',
      i_rx_axi_arcache  => (others => '0'),
      i_rx_axi_arprot   => (others => '0'),
      i_rx_axi_arvalid  => '0',
      o_rx_axi_arready  => open,

      -- AXI read data channel (unused)
      o_rx_axi_rid      => open,
      o_rx_axi_rdata    => open,
      o_rx_axi_rresp    => open,
      o_rx_axi_rlast    => open,
      o_rx_axi_rvalid   => open,
      i_rx_axi_rready   => '0',

      -- input FIFO interface
      i_rx_fifo_read    => '1',
      o_rx_rvalid       => rx_rvalid,
      o_rx_data         => rx_data,
      o_rx_addr         => rx_addr,
      o_rx_fifo_e       => open,
      o_rx_fifo_ae      => open,
      o_rx_fifo_count   => open,
      o_rx_fifo_oflow   => open,
      o_rx_fifo_uflow   => open,
      o_rx_fifo_db      => open,
      o_rx_fifo_sb      => open,

      -- output FIFO interface
      i_tx_fifo_af      => tx_fifo_af,

      -- interface with internal controller
      i_rx_drop_pkts    => rx_drop_pkts,
      i_write_blank_en  => write_blank_en,
      o_write_blank_ack => write_blank_ack
    );

  -- AXI Rx reads not supported
  o_tx_arid    <= (others => '0');
  o_tx_araddr  <= (others => '0');
  o_tx_arlen   <= (others => '0');
  o_tx_arsize  <= (others => '0');
  o_tx_arburst <= (others => '0');
  o_tx_arlock  <= (others => '0');
  o_tx_arcache <= (others => '0');
  o_tx_arprot  <= (others => '0');
  o_tx_arvalid <= '0';
  o_tx_rready  <= '0';

  -- Input FSM
  u_input_fsm : input_fsm
    generic map (
      G_DATA_PKT_WIDTH => ( G_RX_DATA_WIDTH ),
      G_ADDR_PKT_WIDTH => ( 8 )
    )
    port map (
      -- clock and reset interface
      i_macclk          => i_macclk,
      i_rst_n           => rst_n,
      i_por_n           => i_por_n,

      -- signals to and from Input FIFO
      i_rx_pkt          => rx_rvalid,
      i_rx_addr         => rx_addr,
      i_rx_data         => rx_data,

      -- signals to and from AXI Receiver
      i_write_blank_ack => write_blank_ack,
      o_write_blank_en  => write_blank_en,
      o_drop_pkts       => rx_drop_pkts,

      -- TODO: signals to and from Command Buffer
      i_rdata           => (others => '0'),
      i_rvalid          => '0',
      i_state_reg_pls   => '0',
      o_addr            => open,
      o_ren             => open,
      o_wen             => open,
      o_wdata           => open,

      -- global status signals
      i_proc_error      => proc_error,
      i_res_written     => res_written,
      o_cmd_valid       => cmd_valid,
      o_cmd_err         => cmd_err,
      o_cmd_kern        => cmd_kern,
      o_cmd_subj        => cmd_subj,
      o_cmd_kern_signed => cmd_kern_signed,
      o_eor             => eor,
      o_prepad_done     => prepad_done,
      o_payload_done    => payload_done
    );

  ---------------------
  -- Compute submodules
  ---------------------

  -- Clusters
  G_CLUSTER: for i in 1 to 4 generate

  end generate;

  ----------------------------
  -- Output control submodules
  ----------------------------

  -- Output FSM

  -- Output FIFO and AXI Transmitter
  u_tx_buffer: tx_buffer
    generic map (
      -- FIFO capacity
      NWORDS           => ( 512 ),
      AWIDTH           => ( 10 ),
      AEVAL            => ( 4 ),
      AFVAL            => ( 512 - G_CLUSTER_CMPT_LATENCY ),

      -- packet widths
      G_DATA_PKT_WIDTH => ( G_TX_DATA_WIDTH )
    )
    port map (

      -- clock and reset interface
      i_macclk         => i_macclk,
      i_aclk           => i_aclk,
      i_arst_n         => i_arst_n,

      -- interface with internal controller
      i_accept_w       => tx_accept_w,
      i_base_addr      => tx_base_addr,
      i_new_addr       => tx_new_addr,

      -- FIFO interface
      i_w0_wdata       => tx_w0_wdata,
      i_w0_wen         => tx_w0_wen,
      i_w1_wdata       => tx_w1_wdata,
      i_w1_wen         => tx_w1_wen,
      o_tx_fifo_af     => tx_fifo_af,
      o_tx_fifo_db     => open,
      o_tx_fifo_sb     => open,
      o_tx_fifo_oflow  => open,
      o_tx_fifo_uflow  => open,

      -- AXI write address channel
      o_tx_axi_awid    => o_tx_awid,
      o_tx_axi_awaddr  => o_tx_awaddr,
      o_tx_axi_awlen   => o_tx_awlen,
      o_tx_axi_awsize  => o_tx_awsize,
      o_tx_axi_awburst => o_tx_awburst,
      o_tx_axi_awlock  => o_tx_awlock(0),
      o_tx_axi_awcache => o_tx_awcache,
      o_tx_axi_awprot  => o_tx_awprot,
      o_tx_axi_awvalid => o_tx_awvalid,
      i_tx_axi_awready => i_tx_awready,

      -- AXI write data channel
      o_tx_axi_wdata   => o_tx_wdata,
      o_tx_axi_wstrb   => o_tx_wstrb,
      o_tx_axi_wlast   => o_tx_wlast,
      o_tx_axi_wvalid  => o_tx_wvalid,
      i_tx_axi_wready  => i_tx_wready,

      -- AXI write response channel
      i_tx_axi_bid     => i_tx_bid,
      i_tx_axi_bresp   => i_tx_bresp,
      i_tx_axi_bvalid  => i_tx_bvalid,
      o_tx_axi_bready  => o_tx_bready,

      -- AXI read address channel (unused)
      o_tx_axi_arid    => open,
      o_tx_axi_araddr  => open,
      o_tx_axi_arlen   => open,
      o_tx_axi_arsize  => open,
      o_tx_axi_arburst => open,
      o_tx_axi_arlock  => open,
      o_tx_axi_arcache => open,
      o_tx_axi_arprot  => open,
      o_tx_axi_arvalid => open,
      i_tx_axi_arready => '0',

      -- AXI read data channel (unused)
      i_tx_axi_rid     => (others => '0'),
      i_tx_axi_rdata   => (others => '0'),
      i_tx_axi_rresp   => (others => '0'),
      i_tx_axi_rlast   => '0',
      i_tx_axi_rvalid  => '0',
      o_tx_axi_rready  => open
    );
  o_tx_awlock(1) <= '0';

  -- AXI Tx reads not supported
  o_rx_arready <= '0';
  o_rx_rid     <= (others => '0');
  o_rx_rdata   <= (others => '0');
  o_rx_rresp   <= (others => '0');
  o_rx_rlast   <= '0';
  o_rx_rvalid  <= '0';

  ---------------------------
  -- Global memory submodules
  ---------------------------

  -- TODO: APB Receiver
  o_pready  <= '0';
  o_prdata  <= (others => '0');
  o_pslverr <= '0';

  -- Global Memory

end rtl;
