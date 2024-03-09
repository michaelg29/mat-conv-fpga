`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "uvm_macros.svh"

module tb_top();

import uvm_pkg::*;

// clock and reset
localparam time ACLK_PER = `ACLK_PER_PS * 1ps;
localparam time MACCLK_PER = `MACCLK_PER_PS * 1ps;
logic aclk_dut = 1'b1;
logic macclk_dut = 1'b1;
logic arst_n     = 1'b0;

// internal controller
logic [ 1:0] accept_w = '0;
logic [31:0] base_addr = '0;
logic        new_addr = '0;

// FIFO interface
logic [31:0] w0_wdata = '0;
logic        w0_wen = '0;
logic [31:0] w1_wdata = '0;
logic        w1_wen = '0;
wire         tx_fifo_af;
wire         tx_fifo_db;
wire         tx_fifo_sb;
wire         tx_fifo_oflow;
wire         tx_fifo_uflow;

// AXI write address channel
wire  [ 3:0] tx_axi_awid;
wire  [31:0] tx_axi_awaddr;
wire  [ 3:0] tx_axi_awlen;
wire  [ 2:0] tx_axi_awsize;
wire  [ 1:0] tx_axi_awburst;
wire         tx_axi_awlock;
wire  [ 3:0] tx_axi_awcache;
wire  [ 2:0] tx_axi_awprot;
wire         tx_axi_awvalid;
logic        tx_axi_awready = '0;

// AXI write data channel
wire  [63:0] tx_axi_wdata;
wire  [ 7:0] tx_axi_wstrb;
wire         tx_axi_wlast;
wire         tx_axi_wvalid;
logic        tx_axi_wready = '0;

// AXI write response channel
logic [ 3:0] tx_axi_bid = '0;
logic [ 1:0] tx_axi_bresp = '0;
logic        tx_axi_bvalid = '0;
wire         tx_axi_bready;

tx_buffer #(
  .NWORDS(16),
  .AWIDTH(4),
  .G_DATA_PKT_WIDTH(64)
) DUT (
  // clock and reset interface
  .i_macclk            (macclk_dut),
  .i_aclk              (aclk_dut),
  .i_arst_n            (arst_n),

  // interface with internal controller
  .i_accept_w          (accept_w),
  .i_base_addr         (base_addr),
  .i_new_addr          (new_addr),

  // FIFO interface
  .i_w0_wdata          (w0_wdata),
  .i_w0_wen            (w0_wen),
  .i_w1_wdata          (w1_wdata),
  .i_w1_wen            (w1_wen),
  .o_tx_fifo_af        (tx_fifo_af),
  .o_tx_fifo_db        (tx_fifo_db),
  .o_tx_fifo_sb        (tx_fifo_sb),
  .o_tx_fifo_oflow     (tx_fifo_oflow),
  .o_tx_fifo_uflow     (tx_fifo_uflow),

  // AXI write address channel
  .o_tx_axi_awid       (tx_axi_awid),
  .o_tx_axi_awaddr     (tx_axi_awaddr),
  .o_tx_axi_awlen      (tx_axi_awlen),
  .o_tx_axi_awsize     (tx_axi_awsize),
  .o_tx_axi_awburst    (tx_axi_awburst),
  .o_tx_axi_awlock     (tx_axi_awlock),
  .o_tx_axi_awcache    (tx_axi_awcache),
  .o_tx_axi_awprot     (tx_axi_awprot),
  .o_tx_axi_awvalid    (tx_axi_awvalid),
  .i_tx_axi_awready    (tx_axi_awready),

  // AXI write data channel
  .o_tx_axi_wdata      (tx_axi_wdata),
  .o_tx_axi_wstrb      (tx_axi_wstrb),
  .o_tx_axi_wlast      (tx_axi_wlast),
  .o_tx_axi_wvalid     (tx_axi_wvalid),
  .i_tx_axi_wready     (tx_axi_wready),

  // AXI write response channel
  .i_tx_axi_bid        (tx_axi_bid),
  .i_tx_axi_bresp      (tx_axi_bresp),
  .i_tx_axi_bvalid     (tx_axi_bvalid),
  .o_tx_axi_bready     (tx_axi_bready),

  // AXI read address channel
  .o_tx_axi_arid       (),
  .o_tx_axi_araddr     (),
  .o_tx_axi_arlen      (),
  .o_tx_axi_arsize     (),
  .o_tx_axi_arburst    (),
  .o_tx_axi_arlock     (),
  .o_tx_axi_arcache    (),
  .o_tx_axi_arprot     (),
  .o_tx_axi_arvalid    (),
  .i_tx_axi_arready    (1'b0),

  // AXI read data channel
  .i_tx_axi_rid        (4'h0),
  .i_tx_axi_rdata      (64'h0),
  .i_tx_axi_rresp      (2'b00),
  .i_tx_axi_rlast      (1'b0),
  .i_tx_axi_rvalid     (1'b0),
  .o_tx_axi_rready     ()
);

// Clock generation
always #(ACLK_PER / 2) begin
	aclk_dut <= ~aclk_dut;
end
always #(MACCLK_PER / 2) begin
	macclk_dut <= ~macclk_dut;
end

initial begin

  // code that executes only once
	`uvm_info("tb_top", "Running testbench", UVM_NONE);
  #(MACCLK_PER);
  arst_n <= 1'b1;
  #(MACCLK_PER);
  `uvm_info("tb_top", "Done with startup", UVM_NONE);
  #(3*MACCLK_PER);

  accept_w <= 2'b01;
  w1_wdata <= 32'hCAFECAFE;
  w1_wen   <= 1'b1;
  #(MACCLK_PER);
  w1_wen   <= 1'b1;
  w1_wdata <= 32'hBEEFBEEF;
  #(MACCLK_PER);
  w1_wen   <= 1'b0;
  #(MACCLK_PER);
  
  w0_wdata <= 32'hABABABAB;
  w0_wen   <= 1'b1;
  #(MACCLK_PER);
  w0_wen   <= 1'b1;
  w0_wdata <= 32'h12345678;
  #(MACCLK_PER);
  w0_wen   <= 1'b0;
  #(MACCLK_PER);

  #(5*MACCLK_PER);
  `uvm_info("tb_top", "Resetting", UVM_NONE);
  arst_n <= 1'b0;
  #(10*MACCLK_PER);

  `uvm_info("tb_top", "Exiting", UVM_NONE);
  $stop();
end

endmodule
