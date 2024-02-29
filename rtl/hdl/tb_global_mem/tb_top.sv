`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"

module tb_top #(
  parameter string TC="tb_global_mem_lsram" // Name of test case to run
);

import tb_global_mem_pkg::*;

// clock and reset
time ACLK_PER = `ACLK_PER_PS * 1ps;
time MACCLK_PER = `MACCLK_PER_PS * 1ps;
logic w_aclk_dut = 1'b1;
logic w_macclk_dut = 1'b1;
logic rst_n = 1'b0;

// port A input
logic [10:0] A_ADDR = '0;
logic [17:0] A_DIN = '0;
logic [ 1:0] A_WEN = '0;
logic        A_REN = '0;
logic        A_DOUT_REN = '0;

// port A output wires
logic [17:0] A_DOUT;
wire         A_SB_CORRECT;
wire         A_DB_DETECT;

// port B input
logic [10:0] B_ADDR = '0;
logic [17:0] B_DIN = '0;
logic [ 1:0] B_WEN = '0;
logic        B_REN = '0;
logic        B_DOUT_REN = '0;

// port B output wires
logic [17:0] B_DOUT;
wire         B_SB_CORRECT;
wire         B_DB_DETECT;

  if (TC == "tb_global_mem_lsram") begin: DUT_lsram
      // DUT instantiation
      lsram_1024x18 #(
        .A_WIDTH(2'b11),
        .A_WMODE(2'b11),
        .A_DOUT_BYPASS(2'b10),
        .B_WIDTH(2'b11),
        .B_WMODE(2'b11),
        .B_DOUT_BYPASS(2'b10),
        .ECC_EN(2'b11),
        .ECC_DOUT_BYPASS(2'b10),
        .DELEN(2'b10),
        .SECURITY(2'b10)
      ) DUT (
        // port A
        .A_ADDR          (A_ADDR),
        .A_BLK           (3'b111),
        .A_CLK           (w_aclk_dut),
        .A_DIN           (A_DIN),
        .A_DOUT          (A_DOUT),
        .A_WEN           (A_WEN),
        .A_REN           (A_REN),
        .A_DOUT_EN       (1'b1),
        .A_DOUT_SRST_N   (rst_n),
        .A_SB_CORRECT    (A_SB_CORRECT),
        .A_DB_DETECT     (A_DB_DETECT),

        // port B
        .B_ADDR          (B_ADDR),
        .B_BLK           (3'b111),
        .B_CLK           (w_macclk_dut),
        .B_DIN           (B_DIN),
        .B_DOUT          (B_DOUT),
        .B_WEN           (B_WEN),
        .B_REN           (B_REN),
        .B_DOUT_EN       (1'b1),
        .B_DOUT_SRST_N   (rst_n),
        .B_SB_CORRECT    (B_SB_CORRECT),
        .B_DB_DETECT     (B_DB_DETECT),

        // common signals
        .ARST_N          (rst_n),
        .BUSY            ()
      );
  end

// Clock generation
always #(ACLK_PER / 2) begin
	w_aclk_dut <= ~w_aclk_dut;
end
always #(MACCLK_PER / 2) begin
	w_macclk_dut <= ~w_macclk_dut;
end

initial begin

	// code that executes only once
	$display("Running testbench");
  #(ACLK_PER);
  rst_n <= 1'b1;
  $display("Done with startup");

  if (TC == "tb_global_mem_lsram") begin
    tb_global_mem_lsram_wrapper::run_task(
      ACLK_PER,
      w_aclk_dut,
      A_ADDR,
      A_DIN,
      A_WEN,
      A_REN,
      A_DOUT,

      MACCLK_PER,
      w_macclk_dut,
      B_ADDR,
      B_DIN,
      B_WEN,
      B_REN,
      B_DOUT
    );
  end

  $display("Resetting");
  #(ACLK_PER);
  rst_n <= 1'b0;

  $display("Exiting");
  $stop();
end

endmodule
