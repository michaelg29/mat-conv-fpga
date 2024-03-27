`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "../tb_common/mat_conv_tc.svh"
`include "uvm_macros.svh"

module tb_top #(
  parameter string TC="tb_cluster_kernel_size_subject_no_pad", // Name of test case to run
  parameter KERNEL_SIZE = 5,
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
//clock
reg i_clk;
time MACCLK_PER = `MACCLK_PER_PS * 1ps;

//DUT signals
//IN INTERFACE


//========================================
// DUT
//========================================
// interface to DUT instantiation
cluster_if #(
  .FIFO_WIDTH(8)
) intf (
  .i_clk(i_clk)
); 

//DUT
cluster DUT(
    .i_clk(i_clk),

    .i_newrow(intf.i_newrow),
    .i_is_kern(intf.i_is_kern),
    .i_cmd_kern_signed(intf.i_cmd_kern_signed),
    .i_is_subj(intf.i_is_subj),
    .i_new_pkt(intf.i_new_pkt),
    .i_discont(intf.i_discont),
    .i_pkt(intf.i_pkt),
    .o_out_rdy(intf.o_out_rdy), //TODO remove
    .o_pixel(intf.o_pixel)
);


//========================================
// Clocks
//========================================
const int clk_period = 200; //ns (5MHz)

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
      tb_cluster_load_kernel tc = new(intf, MACCLK_PER);
    end
    /*
    "tb_cluster_load_kernel_block":
    begin: tc
      tb_cluster_load_kernel_block tc = new(intf, MACCLK_PER);
    end
    "tb_cluster_kernel_size_subject_no_pad":
    begin: tc
      tb_cluster_kernel_size_subject_no_pad tc = new(intf, MACCLK_PER);
    end // tc
    */
  endcase // TC
endgenerate

initial begin

  // startup sequence
  `uvm_info("tb_top", "Running testbench", UVM_NONE);
  #(MACCLK_PER+1ps);
  
  //reset IP
  intf.reset();

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