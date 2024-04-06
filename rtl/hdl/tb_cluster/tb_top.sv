`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "../tb_common/mat_conv_tc.svh"
`include "uvm_macros.svh"

module tb_top #(
  parameter string TC="tb_cluster_conv", // Name of test case to run
  parameter KERNEL_SIZE = 5,
  parameter NUM_ROWS = 5, //subject image row range
  parameter NUM_COLS = 10, //subject image column range
  parameter PADDING_EN = 1,
  parameter FIFO_WIDTH = 8,
  parameter int NUM_REPS = 3, //Number of times each test shall be reapeated with different values
  parameter int SEED = 0, //Seed for the random input generation
  parameter int VERBOSE = 0, //Enable verbosity for debug
  parameter ROUNDING=3'b100
);

import tb_cluster_pkg::*;
import uvm_pkg::*;

//Set seed for randomization
bit [31:0] dummy = $urandom(SEED);

// generics

//========================================
// Constants
//========================================


//========================================
// Signals
//========================================
//clock and reset
reg i_clk;
reg i_rst_n;
time MACCLK_PER = `MACCLK_PER_PS * 1ps;

//DUT signals
//IN INTERFACE


//========================================
// DUT
//========================================
// interface to DUT instantiation
cluster_if #(
  .FIFO_WIDTH(FIFO_WIDTH),
  .NUM_COLS(NUM_COLS),
  .NUM_ROWS(NUM_ROWS),
  .PADDING_EN(PADDING_EN),
  .KERNEL_SIZE(KERNEL_SIZE)
) intf (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n)
); 

//DUT
cluster DUT(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),

    .i_end_of_row(intf.i_end_of_row),
    .i_is_kern(intf.i_is_kern),
    .i_cmd_kern_signed(intf.i_cmd_kern_signed),
    .i_is_subj(intf.i_is_subj),
    .i_new_pkt(intf.i_new_pkt),
    .i_discont(intf.i_discont),
    .i_pkt(intf.i_pkt),
    .i_waddr(intf.i_waddr),
    .o_out_rdy(intf.o_out_rdy), //TODO remove
    .o_pixel(intf.o_pixel)
);


//========================================
// Clocks
//========================================
const int clk_period = MACCLK_PER; //ns (5MHz)

initial begin
    i_clk = 0;
end

always #(clk_period / 2) begin
    i_clk <= ~i_clk;
end


//========================================
// Test Case Instantiation
//========================================
generate
  case (TC)
    "tb_cluster_load_kernel":
    begin: tc
      tb_cluster_load_kernel #(
        .KERNEL_SIZE(KERNEL_SIZE)
        ) tc = new(intf, MACCLK_PER);
    end
    "tb_cluster_load_kernel_block":
    begin: tc
      tb_cluster_load_kernel_block tc = new(intf, MACCLK_PER);
    end
    "tb_cluster_conv":
    begin: tc
      tb_cluster_conv #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .FIFO_WIDTH(FIFO_WIDTH),
        .NUM_ROWS(NUM_ROWS),
        .NUM_COLS(NUM_COLS),
        .PADDING_EN(PADDING_EN)
        ) tc = new(intf, MACCLK_PER);
    end // tc
  endcase // TC
endgenerate

initial begin

  // startup sequence
  `uvm_info("tb_top", "Running testbench", UVM_NONE);
  #(MACCLK_PER+1ps);
  
  //reset IP
  i_rst_n <= 0;
  intf.reset();
  #(MACCLK_PER);
  i_rst_n <= 1;

  `uvm_info("tb_top", "Completed startup", UVM_NONE);
  #(MACCLK_PER);

  // run testcase
  tc.tc.run();

  // reset sequence
  #(MACCLK_PER);
  //rst_n <= 1'b0;
  #(5*MACCLK_PER);

  `uvm_info("tb_top", "Exiting", UVM_NONE);
  $finish(0);
end

endmodule