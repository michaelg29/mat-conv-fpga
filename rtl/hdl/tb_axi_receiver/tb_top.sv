`timescale 1 ps/ 1 ps
`define ACLK_PER_PS 15625 // 64MHz

`include "uvm_macros.svh"

module tb_top();

import uvm_pkg::*;

// clock and reset
localparam time ACLK_PER = `ACLK_PER_PS * 1ps;
logic aclk_dut = 1'b1;
logic arst_n     = 1'b0;

// write address channel
logic [ 3:0] awid;
logic [31:0] awaddr;
logic [ 3:0] awlen;
logic [ 2:0] awsize;
logic [ 1:0] awburst;
logic        awlock;
logic [ 3:0] awcache;
logic [ 2:0] awprot;
logic        awvalid;
wire         awready;

// write data channel
logic [63:0] wdata;
logic [ 7:0] wstrb;
logic        wlast;
logic        wvalid;
wire         wready;

// write response channel
wire  [ 3:0] bid;
wire  [ 1:0] bresp;
wire         bvalid;
logic        bready;

// input FIFO signals
logic        rx_fifo_af;
wire         rx_valid;
wire  [ 7:0] rx_addr;
wire  [64:0] rx_data;

// input FSM signals
logic        rx_drop_pkts;
logic        write_blank_en;
wire         write_blank_ack;

// DUT instantiation
// axi_receiver DUT (
  // // clock and reset interface
  // .i_aclk                (aclk_dut),
  // .i_arst_n              (arst_n),

  // // write address channel
  // .i_rx_axi_awid         (awid),
  // .i_rx_axi_awaddr       (awaddr),
  // .i_rx_axi_awlen        (awlen),
  // .i_rx_axi_awsize       (awsize),
  // .i_rx_axi_awburst      (awburst),
  // .i_rx_axi_awlock       (awlock),
  // .i_rx_axi_awcache      (awcache),
  // .i_rx_axi_awprot       (awprot),
  // .i_rx_axi_awvalid      (awvalid),
  // .o_rx_axi_awready      (awready),

  // // write data channel
  // .i_rx_axi_wdata        (wdata),
  // .i_rx_axi_wstrb        (wstrb),
  // .i_rx_axi_wlast        (wlast),
  // .i_rx_axi_wvalid       (wvalid),
  // .o_rx_axi_wready       (wready),

  // // write response channel
  // .o_rx_axi_bid          (bid),
  // .o_rx_axi_bresp        (bresp),
  // .o_rx_axi_bvalid       (bvalid),
  // .i_rx_axi_bready       (bready),

  // // read address channel (unused)
  // .i_rx_axi_arid         (),
  // .i_rx_axi_araddr       (),
  // .i_rx_axi_arlen        (),
  // .i_rx_axi_arsize       (),
  // .i_rx_axi_arburst      (),
  // .i_rx_axi_arlock       (),
  // .i_rx_axi_arcache      (),
  // .i_rx_axi_arprot       (),
  // .i_rx_axi_arvalid      (),
  // .o_rx_axi_arready      (),

  // // read data channel (unused)
  // .o_rx_axi_rid          (),
  // .o_rx_axi_rdata        (),
  // .o_rx_axi_rresp        (),
  // .o_rx_axi_rlast        (),
  // .o_rx_axi_rvalid       (),
  // .i_rx_axi_rready       (),

  // // interface with input FIFO
  // .i_rx_fifo_af          (rx_fifo_af),
  // .o_rx_valid            (rx_valid),
  // .o_rx_addr             (rx_addr),
  // .o_rx_data             (rx_data),

  // // interface with internal controller
  // .i_rx_drop_pkts        (rx_drop_pkts),
  // .i_write_blank_en      (write_blank_en),
  // .o_write_blank_ack     (write_blank_ack)
// );

logic wen = 1'b0;
logic ren = 1'b0;

wire aempty;
wire afull;
wire db_detect;
wire empty;
wire full;
wire overflow;
wire [63:0] q;
wire [9:0] rdcnt;
wire sb_correct;
wire underflow;

fifo_64x512 #(
  .AEVAL(4),
  .AFVAL(510)
) DUT (
  .CLK(aclk_dut),
  .RCLK(aclk_dut),
  .WCLK(aclk_dut),
  .DATA(wdata),
  .RE(ren),
  .RESET_N(arst_n),
  .WE(wen),

  .AEMPTY(aempty),
  .AFULL(afull),
  .DB_DETECT(db_detect),
  .EMPTY(empty),
  .FULL(full),
  .OVERFLOW(overflow),
  .Q(q),
  .RDCNT(rdcnt),
  .SB_CORRECT(sb_correct),
  .UNDERFLOW(underflow)
);

// Clock generation
always #(ACLK_PER / 2) begin
	aclk_dut <= ~aclk_dut;
end

initial begin

  #(1ps);

	// code that executes only once
	$display("Running testbench");
	// insert code here --> begin
  #(ACLK_PER);
  arst_n <= 1'b1;
  $display("Done with startup");

  wdata <= 64'hCAFEBEEF;
  wen <= 1'b1;

  #(ACLK_PER);

  wen <= 1'b0;

  #(10*ACLK_PER);

  ren <= 1'b1;

  #(ACLK_PER);

  ren <= 1'b0;

  #(10*ACLK_PER);

  $display("Resetting");
  arst_n <= 1'b0;
  #(10*ACLK_PER);

  $display("Exiting");
  $stop();
end

endmodule
