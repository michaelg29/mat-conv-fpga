`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "../tb_common/mat_conv_tc.svh"
`include "uvm_macros.svh"

module tb_top #(
  parameter string TC="tb_single_trans" // Name of test case to run
);

import tb_template_pkg::*;
import uvm_pkg::*;

// generics

// clock and reset
time MACCLK_PER = `MACCLK_PER_PS * 1ps;
logic w_macclk_dut = 1'b1;
logic rst_n = 1'b0;
logic por_n = 1'b1;

// interface to DUT instantiation
axi_rx_if #(
  .DW(64),
  .AW(8)
) intf (
  .macclk(w_macclk_dut),
  .rst_n(rst_n),
  .por_n(por_n)
);

// DUT instantiation
axi_receiver #(
    // packet widths
    .G_DATA_PKT_WIDTH(64), // width of an AXI data packet
    .G_ADDR_PKT_WIDTH(8)   // required relative address size
  ) DUT (
    // clock and reset interface
    .i_aclk(w_macclk_dut),
    .i_arst_n(rst_n),

    // write address channel
    .i_rx_axi_awid(intf.i_rx_axi_awid),
    .i_rx_axi_awaddr(intf.i_rx_axi_awaddr),
    .i_rx_axi_awlen(intf.i_rx_axi_awlen),
    .i_rx_axi_awsize(intf.i_rx_axi_awsize),
    .i_rx_axi_awburst(intf.i_rx_axi_awburst),
    .i_rx_axi_awlock (intf.i_rx_axi_awlock),
    .i_rx_axi_awcache(intf.i_rx_axi_awcache),
    .i_rx_axi_awprot (intf.i_rx_axi_awprot),
    .i_rx_axi_awvalid(intf.i_rx_axi_awvalid),
    .o_rx_axi_awready(intf.o_rx_axi_awready),

    // write data channel
    .i_rx_axi_wdata  (intf.i_rx_axi_wdata),
    .i_rx_axi_wstrb  (intf.i_rx_axi_wstrb),
    .i_rx_axi_wlast  (intf.i_rx_axi_wlast),
    .i_rx_axi_wvalid (intf.i_rx_axi_wvalid),
    .o_rx_axi_wready (intf.o_rx_axi_wready),

    // write response channel
    .o_rx_axi_bid (intf.o_rx_axi_bid),
    .o_rx_axi_bresp (intf.o_rx_axi_bresp),
    .o_rx_axi_bvalid (intf.o_rx_axi_bvalid),
    .i_rx_axi_bready (intf.i_rx_axi_bready),

    // read address channel (unused)
    .i_rx_axi_arid   (intf.i_rx_axi_arid),
    .i_rx_axi_araddr (intf.i_rx_axi_araddr),
    .i_rx_axi_arlen  (intf.i_rx_axi_arlen),
    .i_rx_axi_arsize (intf.i_rx_axi_arsize),
    .i_rx_axi_arburst(intf.i_rx_axi_arburst),
    .i_rx_axi_arlock (intf.i_rx_axi_arlock),
    .i_rx_axi_arcache(intf.i_rx_axi_arcache),
    .i_rx_axi_arprot (intf.i_rx_axi_arprot),
    .i_rx_axi_arvalid(intf.i_rx_axi_arvalid),
    .o_rx_axi_arready(intf.o_rx_axi_arready),

    // read data channel (unused)
    .o_rx_axi_rid(intf.o_rx_axi_rid),
    .o_rx_axi_rdata(intf.o_rx_axi_rdata),
    .o_rx_axi_rresp(intf.o_rx_axi_rresp),
    .o_rx_axi_rlast(intf.o_rx_axi_rlast),
    .o_rx_axi_rvalid(intf.o_rx_axi_rvalid),
    .i_rx_axi_rready(intf.i_rx_axi_rready),

    // interface with input FIFO
    .i_rx_fifo_af(intf.i_rx_fifo_af),
    .o_rx_valid(intf.o_rx_valid),
    .o_rx_addr(intf.o_rx_addr),
    .o_rx_data(intf.o_rx_data),

    // interface with internal controller
    .i_rx_drop_pkts  (intf.i_rx_drop_pkts),
    .i_write_blank_en(intf.i_write_blank_en),
    .o_write_blank_ack(intf.o_write_blank_ack)
  );



//FIFO
logic wen = 1'b0;
logic ren = 1'b0;

wire aempty;
wire afull;
wire db_detect;
wire empty;
wire full;
wire overflow;
//wire [63:0] q;
wire [71:0] q;
//wire [9:0] rdcnt;
wire [3:0] rdcnt;
wire sb_correct;
wire underflow;

logic [31:0] awaddr;
logic [63:0] wdata = '0;

fifo_DWxNW #(
  .DWIDTH(72),
  .NWORDS(16),
  .AWIDTH(4),
  .AEVAL(4),
  .AFVAL(14)
) fifo_DUT (
  .CLK(aclk_dut),
  .RCLK(macclk_dut),
  .WCLK(aclk_dut),
  .DATA({awaddr[7:0], wdata}),
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
always #(MACCLK_PER / 2) begin
	w_macclk_dut <= ~w_macclk_dut;
end

// instantiate testcase
generate
  case (TC)
    "tb_single_trans":
    begin: tc
      tb_single_trans tc = new(intf, MACCLK_PER);
    end
    default:
    begin: tc
      mat_conv_tc tc = new();
    end // tc
  endcase // TC
endgenerate

initial begin

	// startup sequence
	`uvm_info("tb_top", "Running testbench", UVM_NONE);
  #(MACCLK_PER+1ps);
  rst_n <= 1'b1;
  `uvm_info("tb_top", "Completed startup", UVM_NONE);
  #(MACCLK_PER);

  // run testcase
  tc.tc.run();

  // reset sequence
  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(5*MACCLK_PER);

  `uvm_info("tb_top", "Exiting", UVM_NONE);
  $finish(0);
end

endmodule
