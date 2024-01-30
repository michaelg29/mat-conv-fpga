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
logic por_n = 1'b1;

// input signals
logic [63:0] wdata           = '0;
logic [7:0]  waddr           = '0;
logic        new_pkt         = '0;
logic        write_blank_ack = '0;
logic        read_status     = '0;

// output signals
wire         write_blank_en;
wire         ignore;
wire [31:0]  cmd_data;
wire [2:0]   cmd_data_id;
wire         cmd_data_valid;
wire         eor;
wire         cmd_kern;
wire         cmd_subj;
wire         cmd_valid;
wire         cmd_err;

// variables
int exp = '0;

`define COPY_BITS(dst, src, dst_offset, src_offset, n) for (int unsigned j = 0; j < n; j++) dst[dst_offset+j] = src[src_offset+j]
`define ASSERT_EQ(a, b) if (a != b) $error($sformatf(`"Unexpected data in ``a``. Expected %08h, got %08h`", b, a))

// DUT instantiation
input_fsm #(
  .G_DATA_PKT_WIDTH(64),
  .G_ADDR_PKT_WIDTH(8)
) DUT (
  // clock and reset interface
  .i_macclk(w_macclk_dut),
  .i_rst_n(rst_n),
  .i_por_n(por_n),

  // signals to and from Input FIFO
  .i_wdata(wdata),
  .i_waddr(waddr),
  .i_new_pkt(new_pkt),

  // signals to and from AXI Receiver
  .i_write_blank_ack(write_blank_ack),
  .o_write_blank_en(write_blank_en),
  .o_ignore(ignore),

  // signals to and from APB Receiver
  .i_read_status(read_status),

  // signals to and from Command Buffer
  .o_cmd_data(cmd_data),
  .o_cmd_data_id(cmd_data_id),
  .o_cmd_data_valid(cmd_data_valid),

  // signals to and from Clusters
  .o_eor(eor),

  // global output status signals
  .o_cmd_kern(cmd_kern),
  .o_cmd_subj(cmd_subj),
  .o_cmd_valid(cmd_valid),
  .o_cmd_err(cmd_err)
);

// Clock generation
always #(MACCLK_PER / 2) begin
	w_macclk_dut <= ~w_macclk_dut;
end

initial begin

	// code that executes only once
	$display("Running testbench");
	// insert code here --> begin
  #(MACCLK_PER+1ps);
  rst_n <= 1'b1;
  $display("Done with startup");

  // valid kernel command
  #(MACCLK_PER);
  wdata <= 64'h00000000CAFECAFE; // S_KEY, CMD
  waddr <= 8'h80;
  new_pkt <= '1;
  #(MACCLK_PER);
  wdata <= 64'hABCD000000100055; // SIZE, TX_ADDR
  waddr <= waddr + 8;
  #(MACCLK_PER);
  wdata <= 64'h0000000000000000; // Reserved, TRANS_ID
  waddr <= waddr + 8;
  #(MACCLK_PER);
  wdata <= 64'hBF8E7444DEADBEEF; // E_KEY, CHKSUM
  waddr <= waddr + 8;
  #(MACCLK_PER);
  new_pkt <= '0;
  #(4*MACCLK_PER);

  // reset
  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(MACCLK_PER);
  rst_n <= 1'b1;

  // valid subject command
  #(MACCLK_PER);
  wdata <= 64'h6AF38000CAFECAFE; // S_KEY, CMD
  waddr <= 8'h80;
  new_pkt <= '1;
  #(MACCLK_PER);
  wdata <= 64'hABCD00001FB343AF; // SIZE, TX_ADDR
  waddr <= waddr + 8;
  #(MACCLK_PER);
  wdata <= 64'h0000000100000000; // Reserved, TRANS_ID
  waddr <= waddr + 8;
  #(MACCLK_PER);
  wdata <= 64'hCADEB7BFDEADBEEF; // E_KEY, CHKSUM
  waddr <= waddr + 8;
  #(MACCLK_PER);
  new_pkt <= '0;
  #(4*MACCLK_PER);

  // reset
  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(MACCLK_PER);
  rst_n <= 1'b1;

  // invalid kernel command
  #(MACCLK_PER);
  wdata <= 64'h00000000BEEFCAFE; // S_KEY, CMD
  waddr <= 8'h80;
  new_pkt <= '1;
  #(MACCLK_PER);
  wdata <= 64'hABCD0000002000A5; // SIZE, TX_ADDR
  waddr <= waddr + 8;
  #(MACCLK_PER);
  new_pkt <= '0;
  #(4*MACCLK_PER);

  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(MACCLK_PER);

  $display("Exiting");
  $stop();
end

endmodule
