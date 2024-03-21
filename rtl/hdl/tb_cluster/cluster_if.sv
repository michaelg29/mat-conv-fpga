`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "uvm_macros.svh"

// interface to wrap around the cluster
interface cluster_if #(
  parameter FIFO_WIDTH=8
) (
  // clock and reset interface
  input logic i_clk,
  input logic i_rst
);

  import uvm_pkg::*;

  logic i_newrow;
  logic i_is_kern;
  logic i_cmd_kern_signed;
  logic i_is_subj;
  logic i_new_pkt;
  logic i_discont;
  logic [FIFO_WIDTH-1:0][7:0] i_pkt; //input pixels from FIFO and/or buffered pixels

  wire [7:0] o_pixel;
  wire o_out_rdy;

  // clocked block
  clocking cb @(posedge i_clk);
    input #0 i_newrow, i_is_kern, i_cmd_kern_signed, i_is_subj, i_new_pkt, i_discont, i_pkt;
    output o_pixel, o_out_rdy;
  endclocking;

endinterface // input_fsm_if