`timescale 1 ps/ 1 ps
`define CLK_PER_PS 2500

`include "uvm_macros.svh"

interface fifo_sync_if #(
  parameter W_EL=8,
  parameter N_IN_EL=1
) (
  input logic i_clk,
  input logic i_rst_n
);

  import uvm_pkg::*;

  logic                    ren = '0;
  logic [W_EL*N_IN_EL-1:0] wdata = '0;
  logic                    wen = '0;
  wire  [W_EL-1:0]         rdata;
  wire                     empty;
  wire                     full;
  wire                     rvalid;
  wire                     rerr;
  wire                     wvalid;
  wire                     werr;
  
  clocking cb @ (posedge i_clk);
    input rdata, empty, full, rvalid, rerr, wvalid, werr;
    output ren, wen, wdata;
  endclocking;
  
  task write (input  [W_EL*N_IN_EL-1:0] i_wdata);
    cb.wdata <= i_wdata;
    @cb;
    cb.wen   <= 1'b1;
    @cb;
    cb.wen   <= 1'b0;
    while (!(cb.wvalid == 1'b0 && cb.werr == 1'b0)) @cb;
    
    //`uvm_info("tb_top", $sformatf("Wrote %08h, valid is %b, err is %b, full is %b", i_wdata, cb.wvalid, cb.werr, cb.full), UVM_NONE);
    `uvm_info("tb_top", $sformatf("Wrote %08h, valid is %b, err is %b, full is %b", i_wdata, wvalid, werr, full), UVM_NONE);
    @cb;
  endtask
  
  task read (output [W_EL-1:0] o_rdata);
    cb.ren <= 1'b1;
    @cb;
    cb.ren <= 1'b0;
    while (!(cb.rvalid == 1'b0 && cb.rerr == 1'b0)) @cb;
    o_rdata  <= cb.rdata;
    
    //`uvm_info("tb_top", $sformatf("Read %08h, valid is %b, err is %b, empty is %b", cb.rdata, cb.rvalid, cb.rerr, cb.empty), UVM_NONE);
    `uvm_info("tb_top", $sformatf("Read %08h, valid is %b, err is %b, empty is %b", rdata, rvalid, rerr, empty), UVM_NONE);
    @cb;
  endtask
  
  task burst_read (input integer unsigned n);
    @cb;
    cb.ren <= 1'b1;
    for (integer unsigned i = 0; i < n; ++i) begin
      @cb;
      //`uvm_info("tb_top", $sformatf("%0d: Read %08h, valid is %b, err is %b, empty is %b", i, cb.rdata, cb.rvalid, cb.rerr, cb.empty), UVM_NONE);
      `uvm_info("tb_top", $sformatf("%0d: Read %08h, valid is %b, err is %b, empty is %b", i, rdata, rvalid, rerr, empty), UVM_NONE);
    end
    cb.ren <= 1'b0;
    @cb;
  endtask
             
endinterface

module tb_top();

import uvm_pkg::*;

// generics
localparam integer ADDR_WIDTH = 5;
localparam integer W_EL = 8;
localparam integer N_IN_EL = 8;
localparam integer W_IN = W_EL * N_IN_EL;

// clock and reset
localparam time CLK_PER = `CLK_PER_PS * 1ps;
localparam time HLF_CLK_PER = CLK_PER / 2;
logic w_clk_dut = 1'b1;
logic rst_n = 1'b0;

// test vector input registers
logic [W_EL-1:0] wdata = '0;
logic [W_IN-1:0] wdata_mult = '0;
logic            wen = '0;
logic            ren = '0;

// wires
wire [W_EL-1:0] rdata;
wire            empty;
wire            full;
wire            rvalid;
wire            rerr;
wire            wvalid;
wire            werr;
wire [W_EL-1:0] rdata_mult;
wire            empty_mult;
wire            full_mult;
wire            rvalid_mult;
wire            rerr_mult;
wire            wvalid_mult;
wire            werr_mult;

// DUT instantiation
fifo_sync #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .W_EL(W_EL)
) DUT (
  .i_clk(w_clk_dut),
  .i_rst_n(rst_n),
  .i_wdata(wdata),
  .i_wen(wen),
  .i_ren(ren),
  .o_rdata(rdata),
  .o_empty(empty),
  .o_full(full),
  .o_rvalid(rvalid),
  .o_rerr(rerr),
  .o_wvalid(wvalid),
  .o_werr(werr)
);

fifo_sync_if#(W_EL, N_IN_EL) u_fifo_sync_if(w_clk_dut, rst_n);
fifo_sync_multw #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .W_EL(W_EL),
  .N_IN_EL(N_IN_EL)
) DUT2 (
  .i_clk(w_clk_dut),
  .i_rst_n(rst_n),
  .i_wdata(u_fifo_sync_if.wdata),
  .i_wen(u_fifo_sync_if.wen),
  .i_ren(u_fifo_sync_if.ren),
  .o_rdata(u_fifo_sync_if.rdata),
  .o_empty(u_fifo_sync_if.empty),
  .o_full(u_fifo_sync_if.full),
  .o_rvalid(u_fifo_sync_if.rvalid),
  .o_rerr(u_fifo_sync_if.rerr),
  .o_wvalid(u_fifo_sync_if.wvalid),
  .o_werr(u_fifo_sync_if.werr)
);

// Clock generation
always #(HLF_CLK_PER) begin
	w_clk_dut <= ~w_clk_dut;
end

initial begin
  logic [W_EL-1:0] rdata_mult;
  logic [W_EL-1:0] wdata_arr[8];
  wdata_arr = '{8'hBE, 8'hEF, 8'hCA, 8'hFE, 8'hDE, 8'hEF, 8'h12, 8'h34};
  
  #(1ps);

	`uvm_info("tb_top", $sformatf("Running testbench"), UVM_NONE);
  #(20*CLK_PER);
  rst_n <= 1'b1;
  `uvm_info("tb_top", $sformatf("Done with startup"), UVM_NONE);
  
  u_fifo_sync_if.write(64'h0123456789ABCDEF);
  u_fifo_sync_if.write(64'hFEDCBA9876543210);
  `uvm_info("tb_top", $sformatf("empty is %b", u_fifo_sync_if.empty), UVM_NONE);
  u_fifo_sync_if.read(rdata_mult);
  u_fifo_sync_if.burst_read(6);
  #(5*CLK_PER);
  u_fifo_sync_if.burst_read(1);
    
  #(10*CLK_PER);
  `uvm_info("tb_top", $sformatf("Resetting"), UVM_NONE);
  rst_n <= 1'b0;
  #(10*CLK_PER);
  
  `uvm_info("tb_top", $sformatf("Exiting"), UVM_NONE);
  $stop();
end

endmodule
