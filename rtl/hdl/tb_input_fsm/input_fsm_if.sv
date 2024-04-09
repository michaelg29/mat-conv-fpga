`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "uvm_macros.svh"

// interface to wrap around the Input FSM
interface input_fsm_if #(
  parameter DW=64,
  parameter AW=8
) (
  // clock and reset interface
  input logic macclk,
  input logic rst_n,
  input logic por_n
);

  import uvm_pkg::*;

  // signals to and from Input FIFO
  logic          rx_pkt = '0;
  logic [AW-1:0] rx_addr = '0;
  logic [DW-1:0] rx_data = '0;

  // signals to and from AXI Receiver
  logic          write_blank_ack = '0;
  wire           write_blank_en;
  wire           drop_pkts;

  // signals to and from Command Buffer
  logic [31:0]   rdata = '0;
  logic          rvalid = '0;
  logic          state_reg_pls = '0;
  wire  [ 2:0]   addr;
  wire           ren;
  wire           wen;
  wire  [31:0]   wdata;

  // global status signals
  logic          proc_error = '0;
  logic          res_written = '0;
  wire           cmd_valid;
  wire           cmd_err;
  wire           cmd_kern;
  wire           cmd_subj;
  wire           cmd_kern_signed;
  wire           eor;
  wire           prepad_done;
  wire           payload_done;

  // clocked block
  clocking cb @(posedge macclk);
    input #0 write_blank_en, drop_pkts, addr, ren, wen, wdata, cmd_valid, cmd_err, cmd_kern, cmd_subj, cmd_kern_signed, eor, prepad_done, payload_done;
    output rx_pkt, rx_addr, rx_data, write_blank_ack, rdata, rvalid, state_reg_pls, proc_error, res_written;
  endclocking;

  // issue a command to the interface in 4 64b packets
  task send_cmd(
    input logic [29:0] out_addr,
    input logic        cmd_type,
    input logic        kern_signed,
    input logic [29:0] size,
    input logic [31:0] tx_addr,
    input logic [31:0] trans_id,
    input logic [31:0] s_key = 32'hCAFECAFE,
    input logic [31:0] e_key = 32'hDEADBEEF,
    input logic        invalid_chksum = 1'b0
  );
    // calculate checksum
    automatic logic [31:0] chksum = s_key ^
      {kern_signed, cmd_type, out_addr} ^
      {2'b0, size} ^
      tx_addr ^
      trans_id ^
      32'b0 ^
      e_key;

    `uvm_info("input_fsm_if", $sformatf("Sending command %08x", {kern_signed, cmd_type, out_addr}), UVM_NONE);

    // invalidate checksum
    if ((invalid_chksum == 1'b1)) begin
      `uvm_info("input_fsm_if", "Invalidating checksum", UVM_NONE);
      chksum = chksum + 1;
    end
    `uvm_info("input_fsm_if", $sformatf("Checksum is %08x", chksum), UVM_NONE);

    @cb;
    cb.rx_pkt <= 1'b1;

    // S_KEY, CMD
    cb.rx_addr <= 8'h80;
    cb.rx_data <= {kern_signed, cmd_type, out_addr, s_key};
    @cb;

    // check output
    if ((cmd_type == 1'b1)) begin
      `ASSERT_EQ(cb.addr, 3'b001, %3b);
      `ASSERT_EQ(cb.wen, 1'b1, %b);
      `ASSERT_EQ(cb.wdata, {out_addr, 2'b0}, %08x);
    end

    // SIZE, TX_ADDR
    cb.rx_addr <= 8'h88;
    cb.rx_data <= {tx_addr, 2'b0, size};
    @cb;

    // check output
    `ASSERT_EQ(cb.addr, 3'b010, %3b);
    `ASSERT_EQ(cb.wen, 1'b1, %b);
    `ASSERT_EQ(cb.wdata, tx_addr, %08x);

    // TRANS_ID, reserved
    cb.rx_addr <= 8'h90;
    cb.rx_data <= {32'b0, trans_id};
    @cb;

    // E_KEY, CHKSUM
    cb.rx_addr <= 8'h98;
    cb.rx_data <= {chksum, e_key};
    @cb;

    cb.rx_pkt <= 1'b0;

    #(1ps); // resynchronize with external tb (read right after rising edge)
  endtask

endinterface // input_fsm_if
