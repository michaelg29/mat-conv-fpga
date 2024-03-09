
`include "uvm_macros.svh"

// interface to wrap around the Input FSM
interface axi_rx_if #(
  parameter DW=64,
  parameter AW=8
) (
  // clock and reset interface
  input logic macclk,
  input logic rst_n,
  input logic por_n
);

  import uvm_pkg::*;

  // write address channel
  logic [3:0] i_rx_axi_awid;
  logic [31:0] i_rx_axi_awaddr;
  logic [3:0] i_rx_axi_awlen;
  logic [2:0] i_rx_axi_awsize;
  logic [1:0] i_rx_axi_awburst;
  logic i_rx_axi_awlock ;
  logic [3:0] i_rx_axi_awcache;
  logic [2:0] i_rx_axi_awprot ;
  logic i_rx_axi_awvalid;
  logic o_rx_axi_awready;

  // write data channel
  logic [63:0] i_rx_axi_wdata  ;
  logic [7:0] i_rx_axi_wstrb  ;
  logic i_rx_axi_wlast  ;
  logic i_rx_axi_wvalid ;
  logic o_rx_axi_wready ;

  // write response channel
  logic [3:0] o_rx_axi_bid ;
  logic [31:0] o_rx_axi_bresp ;
  logic o_rx_axi_bvalid ;
  logic i_rx_axi_bready ;

  // read address channel (unused)
  logic [3:0] i_rx_axi_arid   ;
  logic [31:0] i_rx_axi_araddr ;
  logic [3:0] i_rx_axi_arlen  ;
  logic [2:0] i_rx_axi_arsize ;
  logic [1:0] i_rx_axi_arburst;
  logic i_rx_axi_arlock ;
  logic [3:0] i_rx_axi_arcache;
  logic [2:0] i_rx_axi_arprot ;
  logic i_rx_axi_arvalid;
  logic o_rx_axi_arready;

  // read data channel (unused)
  logic [3:0] o_rx_axi_rid;
  logic [63:0] o_rx_axi_rdata;
  logic [1:0] o_rx_axi_rresp;
  logic o_rx_axi_rlast;
  logic o_rx_axi_rvalid;
  logic i_rx_axi_rready;

  // interface with input FIFO
  logic i_rx_fifo_af;
  logic o_rx_valid;
  logic [AW-1:0] o_rx_addr;
  logic [DW-1:0] o_rx_data;

  // interface with internal controller
  logic i_rx_drop_pkts ;
  logic i_write_blank_en;
  logic o_write_blank_ack;

endinterface // input_fsm_if
