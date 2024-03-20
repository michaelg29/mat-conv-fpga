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
parameter UNSIGNED_UPPER_BOUND = 12'b111111111111;
parameter SIGNED_UPPER_BOUND = 12'b011111111111;
parameter SIGNED_LOWER_BOUND = 12'b100000000000;


//========================================
// Signals
//========================================
//clock
reg i_clk;
time MACCLK_PER = `MACCLK_PER_PS * 1ps;

//DUT signals
logic i_newrow;
logic i_is_kern;
logic i_cmd_kern_signed;
logic i_is_subj;
logic i_new_pkt;
logic i_discont;
logic [FIFO_WIDTH-1:0][7:0] i_pkt; //input pixels from FIFO and/or buffered pixels
logic [7:0] o_pixel;
logic o_out_rdy;


//========================================
// DUT
//========================================
// interface to DUT instantiation
cluster_if #(
  .DW(64)
) intf (
  .macclk(w_macclk_dut),
  .rst_n(rst_n),
  .por_n(por_n)
);

//DUT
cluster DUT(
    .i_clk(i_clk),
    .i_newrow(i_newrow),
    .i_is_kern(i_is_kern),
    .i_cmd_kern_signed(i_cmd_kern_signed),
    .i_is_subj(i_is_subj),
    .i_new_pkt(i_new_pkt),
    .i_discont(i_discont),
    .i_pkt(i_pkt),
    .o_out_rdy(o_out_rdy), //TODO remove
    .o_pixel(o_pixel)
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
    "tb_cluster_load_kernel_block":
    begin: tc
      tb_cluster_load_kernel_block tc = new(intf, MACCLK_PER);
    end
    "tb_cluster_kernel_size_subject_no_pad":
    begin: tc
      tb_cluster_kernel_size_subject_no_pad tc = new(intf, MACCLK_PER);
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
  $stop();
end

endmodule