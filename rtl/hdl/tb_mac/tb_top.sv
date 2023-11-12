// Copyright (C) 2021  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.

// *****************************************************************************
// This file contains a Verilog test bench template that is freely editable to  
// suit user's needs .Comments are provided in each section to help the user    
// fill out necessary details.                                                  
// *****************************************************************************
// Generated on "08/05/2023 11:36:53"
                                                                                
// Verilog Test Bench template for design : dut_top
// 
// Simulation tool : ModelSim (Verilog)
// 

`timescale 1 ps/ 1 ps
`define CLK_PER_PS 2500

module tb_top();

import test_pkg::*;

// clock
localparam time CLK_PER = `CLK_PER_PS * 1ps;
localparam time HLF_CLK_PER = CLK_PER / 2;
logic w_clk_dut = 1'b1;

// test vector input registers
logic       mult = 1'b0;
logic       acc  = 1'b0;
logic [7:0] a    = '0;
logic [7:0] b    = '0;

// wires
wire [7:0] f;

int exp = 8'h0;

// assign statements
mac #(
  .W(8)
) DUT (
	.i_clk   (w_clk_dut),
  .i_mult  (mult),
  .i_acc   (acc),
  .i_a     (a),
  .i_b     (b),
  .o_f     (f)
);

always #(HLF_CLK_PER) begin
	w_clk_dut <= ~w_clk_dut;
end

initial begin
  test_class::print_hello();
  test_class::uvm_log();
	// code that executes only once
	$display("Running testbench");
	// insert code here --> begin
  #(20*CLK_PER);
  $display("Done with startup");
  
  $display("Driving inputs in reset mode");
	a <= 8'hAB;
	b <= 8'hBC;
  exp = 8'h0;
  #(HLF_CLK_PER);
  for (int i = 0; i < 10; ++i) begin
    #(CLK_PER);
    $display("a: %02h, b: %02h, f: %02h, exp: %02h", a, b, f, exp[7:0]);
    if (f != exp[7:0]) begin
      $error("Invalid output data");
    end
  end
  #(HLF_CLK_PER);
  
  $display("Driving inputs in multiply mode");
  mult <= 1'b1;
  exp = a * b;
  #(HLF_CLK_PER);
  for (int i = 0; i < 10; ++i) begin
    #(CLK_PER);
    $display("a: %02h, b: %02h, f: %02h, exp: %02h", a, b, f, exp[7:0]);
    if (f != exp[7:0]) begin
      $error("Invalid output data");
    end
  end
  #(HLF_CLK_PER);
  
  $display("Driving inputs in latch mode");
  mult <= 1'b0;
  acc <= 1'b1;
  #(HLF_CLK_PER);
  for (int i = 0; i < 10; ++i) begin
    #(CLK_PER);
    $display("a: %02h, b: %02h, f: %02h, exp: %02h", a, b, f, exp[7:0]);
    if (f != exp[7:0]) begin
      $error("Invalid output data");
    end
  end
  #(HLF_CLK_PER);
  
  $display("Driving inputs in MAC mode");
  mult <= 1'b1;
  #(HLF_CLK_PER);
  for (int i = 0; i < 10; ++i) begin
    exp += a * b;
    #(CLK_PER);
    $display("a: %02h, b: %02h, f: %02h, exp: %02h", a, b, f, exp[7:0]);
    if (f != exp[7:0]) begin
      $error("Invalid output data");
    end
  end
  #(HLF_CLK_PER);
  
  $display("Resetting");
  mult <= 1'b0;
  acc <= 1'b0;
  #(10*CLK_PER);
  
  $display("Exiting");
  $stop();
end

endmodule

