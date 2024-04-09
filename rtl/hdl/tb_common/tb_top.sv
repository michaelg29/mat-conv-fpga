`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "../tb_common/mat_conv_tc.svh"
`include "uvm_macros.svh"

module tb_top #(
  parameter string TC="tb_template_tc" // Name of test case to run
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

// DUT instantiation

// Clock generation
always #(MACCLK_PER / 2) begin
	w_macclk_dut <= ~w_macclk_dut;
end

// instantiate testcase
generate
  case (TC)
    "tb_template_tc":
    begin: tc
      tb_template_tc tc = new(/*intf, */MACCLK_PER);
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
  $stop();
end

endmodule
