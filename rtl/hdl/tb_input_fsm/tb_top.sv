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
logic [63:0] pktdata         = '0;
logic [7:0]  pktaddr         = '0;
logic        new_pkt         = '0;
logic        write_blank_ack = '0;
logic [31:0] rdata           = '0;
logic        rvalid          = '0;
logic        state_reg_pls   = '0;
logic        proc_error      = '0;
logic        res_written     = '0;

// output signals
wire         write_blank_en;
wire         drop_pkts;
wire [2:0]   addr;
wire         ren;
wire         wen;
wire [31:0]  wdata;
wire         eor;
wire         cmd_kern;
wire         cmd_subj;
wire         cmd_kern_signed;
wire         cmd_valid;
wire         cmd_err;
wire         payload_done;
wire         o_rst_n;

`define ASSERT_EQ(a, b, format="%08h") if (a != b) `uvm_error("tb_top", $sformatf(`"Unexpected data in ``a``. Expected format, got format`", b, a))

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
  .i_new_pkt(new_pkt),
  .i_wdata(pktdata),
  .i_waddr(pktaddr),

  // signals to and from AXI Receiver
  .i_write_blank_ack(write_blank_ack),
  .o_write_blank_en(write_blank_en),
  .o_drop_pkts(drop_pkts),

  // signals to and from Command Buffer
  .i_rdata(rdata),
  .i_rvalid(rvalid),
  .i_state_reg_pls(state_reg_pls),
  .o_addr(addr),
  .o_ren(ren),
  .o_wen(wen),
  .o_wdata(wdata),

  // global status signals
  .i_proc_error(proc_error),
  .i_res_written(res_written),
  .o_cmd_kern(cmd_kern),
  .o_cmd_subj(cmd_subj),
  .o_cmd_kern_signed(cmd_kern_signed),
  .o_cmd_valid(cmd_valid),
  .o_cmd_err(cmd_err),
  .o_eor(eor),
  .o_payload_done(payload_done),
  .o_rst_n(o_rst_n)
);

// Clock generation
always #(MACCLK_PER / 2) begin
	w_macclk_dut <= ~w_macclk_dut;
end

initial begin

	// startup sequence
	`uvm_info("tb_top", "Running testbench", UVM_NONE);
  #(MACCLK_PER+1ps);
  rst_n <= 1'b1;
  `uvm_info("tb_top", "Completed startup", UVM_NONE);

  // ================================
  // ===== VALID KERNEL COMMAND =====
  // ================================
  #(MACCLK_PER);
  pktdata <= 64'h00000000CAFECAFE; // S_KEY, CMD
  pktaddr <= 8'h80;
  new_pkt <= '1;
  #(MACCLK_PER);
  pktdata <= 64'hABCD000000100055; // SIZE, TX_ADDR
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  pktdata <= 64'h0000000000000000; // Reserved, TRANS_ID
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  pktdata <= 64'hBF8E7444DEADBEEF; // E_KEY, CHKSUM
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  new_pkt <= '0;
  #(MACCLK_PER);
  // check output
  `uvm_info("tb_top", "transmitted cmd", UVM_NONE);
  `ASSERT_EQ(write_blank_en, '0, %b);
  `ASSERT_EQ(drop_pkts, '0, %b);
  //`ASSERT_EQ(cmd_stat_valid, '0, %b);
  `ASSERT_EQ(eor, '0, %b);
  `ASSERT_EQ(cmd_kern, '1, %b);
  `ASSERT_EQ(cmd_subj, '0, %b);
  `ASSERT_EQ(cmd_valid, '1, %b);
  `ASSERT_EQ(cmd_err, '0, %b);
  #(4*MACCLK_PER);

  // =======================
  // ===== KERNEL DATA =====
  // =======================
  pktaddr <= 8'h00;
  for (int unsigned i = 0; i < 4; i++) begin
    `uvm_info("tb_top", $sformatf("Transmitting kernel packet %d", i), UVM_NONE);
    new_pkt <= '1;
    pktdata <= 64'h0101010101010101;
    #(MACCLK_PER);
    pktaddr <= pktaddr + 8;
  end
  new_pkt <= '0;
  #(MACCLK_PER);

  // reset
  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(MACCLK_PER);
  rst_n <= 1'b1;

  // =================================
  // ===== VALID SUBJECT COMMAND =====
  // =================================
  #(MACCLK_PER);
  pktdata <= 64'h6AF38000CAFECAFE; // S_KEY, CMD
  pktaddr <= 8'h80;
  new_pkt <= '1;
  #(MACCLK_PER);
  pktdata <= 64'hABCD00001FB343AF; // SIZE, TX_ADDR
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  pktdata <= 64'h0000000100000000; // Reserved, TRANS_ID
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  pktdata <= 64'hCADEB7BFDEADBEEF; // E_KEY, CHKSUM
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  new_pkt <= '0;
  #(4*MACCLK_PER);

  // ========================
  // ===== SUBJECT DATA =====
  // ========================
  pktaddr <= 8'h00;
  for (int unsigned i = 0; i < 16; i++) begin
    `uvm_info("tb_top", $sformatf("Transmitting subject packet %d", i), UVM_NONE);
    new_pkt <= '1;
    pktdata <= 64'h0101010101010101;
    #(MACCLK_PER);
    pktaddr <= pktaddr + 8;
  end
  new_pkt <= '0;
  #(MACCLK_PER);

  // reset
  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(MACCLK_PER);
  rst_n <= 1'b1;

  // ==================================
  // ===== INVALID KERNEL COMMAND =====
  // ==================================
  #(MACCLK_PER);
  pktdata <= 64'h00000000BEEFCAFE; // S_KEY, CMD
  pktaddr <= 8'h80;
  new_pkt <= '1;
  #(MACCLK_PER);
  pktdata <= 64'hABCD0000002000A5; // SIZE, TX_ADDR
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  pktdata <= 64'h0000000000000000; // Reserved, TRANS_ID
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  pktdata <= 64'h0123456789ABCDEF; // E_KEY, CHKSUM
  pktaddr <= pktaddr + 8;
  #(MACCLK_PER);
  new_pkt <= '0;
  #(MACCLK_PER);
  // check output
  `uvm_info("tb_top", "transmitted cmd", UVM_NONE);
  `ASSERT_EQ(write_blank_en, '0, %b);
  `ASSERT_EQ(drop_pkts, '0, %b);
  //`ASSERT_EQ(cmd_stat_valid, '0, %b);
  `ASSERT_EQ(eor, '0, %b);
  `ASSERT_EQ(cmd_kern, '0, %b);
  `ASSERT_EQ(cmd_subj, '0, %b);
  `ASSERT_EQ(cmd_valid, '0, %b);
  `ASSERT_EQ(cmd_err, '1, %b);
  #(MACCLK_PER);
  // check output
  `ASSERT_EQ(wdata, 32'h0000000E, %08h);
  `ASSERT_EQ(wen, '1, %b);
  #(MACCLK_PER);
  `ASSERT_EQ(wen, '0, %b);
  #(4*MACCLK_PER);

  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(MACCLK_PER);

  `uvm_info("tb_top", "Exiting", UVM_NONE);
  $stop();
end

endmodule
