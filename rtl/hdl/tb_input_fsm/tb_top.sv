`timescale 1 ps/ 1 ps
`define MACCLK_PER_PS 4000  // 250MHz

`define N 8
`define W_BUS 64
`define W_EL 8

`include "uvm_macros.svh"

module tb_top();

import uvm_pkg::*;

// generics

// clock and reset
localparam time MACCLK_PER = `MACCLK_PER_PS * 1ps;
logic w_macclk_dut = 1'b1;
logic rst_n = 1'b0;

// reader clock domain
logic              asel = '0;
logic              bsel = '0;
logic [`W_BUS-1:0] bdata = '0;
wire  [`W_EL -1:0] res;
wire               done;

int exp = '0;

`define COPY_BITS(dst, src, dst_offset, src_offset, n) for (int unsigned j = 0; j < n; j++) dst[dst_offset+j] = src[src_offset+j]
`define ASSERT_EQ(a, b) if (a != b) $error($sformatf(`"Unexpected data in ``a``. Expected %08h, got %08h`", b, a))

// DUT instantiation
input_fsm #(
  .G_DATA_PKT_WIDTH(64),
  .G_ADDR_PKT_WIDTH(8)
) DUT (

);
core #(
  .N(`N),
  .W_EL(`W_EL),
  .W_IN(`W_BUS)
) DUT (
  .i_rst_n  (rst_n),
  
  .i_bclk(w_bclk_dut),
  .i_asel(asel),
  .i_bsel(bsel),
  .i_bdata(bdata),
  .o_res(res),
  .o_done(done),
  
  .i_macclk(w_macclk_dut)
);

// Clock generation
always #(BCLK_PER / 2) begin
	w_bclk_dut <= ~w_bclk_dut;
end
always #(MACCLK_PER / 2) begin
	w_macclk_dut <= ~w_macclk_dut;
end

initial begin

	// code that executes only once
	$display("Running testbench");
	// insert code here --> begin
  #(BCLK_PER);
  rst_n <= 1'b1;
  $display("Done with startup");
  
  bdata <= 64'hBEEFCAFECAEFDEBC;
  asel <= 1'b1;
  bsel <= 1'b0;
  #(BCLK_PER);
  asel <= 1'b0;
  #(8*BCLK_PER);
  asel <= 1'b0;
  bsel <= 1'b1;
  #(BCLK_PER);
  bsel <= 1'b0;
  #(8*BCLK_PER);
  asel <= 1'b0;
  bsel <= 1'b0;
  
  `ASSERT_EQ(res, exp[7:0]);
  @(posedge w_macclk_dut);
  #(3*MACCLK_PER); // startup: 1CC to enable, 1CC to read from FIFO, 1CC to output first result
  $display("Reading outputs for 8 CC");
  for (int i = 0; i < `N; ++i) begin
    logic [`W_EL-1:0] factor;
    `COPY_BITS(factor, bdata, 0, i*8, 8);
    exp += factor * factor;
    #(MACCLK_PER);
    $display("CC %0d: multiplied %02h * %02h, res = %02h, exp = %02h", i, factor, factor, res, exp[7:0]);
    `ASSERT_EQ(res, exp[7:0]);
  end
  
  `ASSERT_EQ(done, 1'b1);
    
  $display("Resetting");
  rst_n <= 1'b0;
  #(MACCLK_PER);
  `ASSERT_EQ(res, '0);
  #(10*MACCLK_PER);
  
  $display("Exiting");
  $stop();
end

endmodule
