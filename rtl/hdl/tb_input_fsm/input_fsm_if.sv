
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

endinterface // input_fsm_if
