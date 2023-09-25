

`include "uvm_macros.svh"

interface fifo_sync_if #(
  parameter W_EL=8,
  parameter N_IN_EL=1
) (
  input logic i_rst_n,
  input logic i_rclk,
  input logic i_wclk
);

  import uvm_pkg::*;
  
  // reader clock domain
  logic                    ren = '0;
  wire  [W_EL-1:0]         rdata;
  wire                     empty;
  wire                     rvalid;
  wire                     rerr;
  
  // writer clock domain
  logic [W_EL*N_IN_EL-1:0] wdata = '0;
  logic                    wen = '0;
  wire                     full;
  wire                     wvalid;
  wire                     werr;
  
  // reader clock domain clocked block
  clocking rcb @ (posedge i_rclk);
    input rdata, full, rvalid, rerr;
    output ren;
  endclocking;
  
  // writer clock domain clocked block
  clocking wcb @ (posedge i_wclk);
    input full, wvalid, werr;
    output wen, wdata;
  endclocking;
  
  task write (input  [W_EL*N_IN_EL-1:0] i_wdata);
    wcb.wdata <= i_wdata;
    @wcb;
    wcb.wen   <= 1'b1;
    @wcb;
    wcb.wen   <= 1'b0;
    while (!(wcb.wvalid == 1'b0 && wcb.werr == 1'b0)) @wcb;
    
    `uvm_info("tb_top", $sformatf("Wrote %08h, valid is %b, err is %b, full is %b", i_wdata, wvalid, werr, full), UVM_NONE);
    @wcb;
  endtask
  
  task read (output [W_EL-1:0] o_rdata);
    rcb.ren <= 1'b1;
    @rcb;
    rcb.ren <= 1'b0;
    while (!(rcb.rvalid == 1'b0 && rcb.rerr == 1'b0)) @rcb;
    o_rdata  <= rcb.rdata;
    
    `uvm_info("tb_top", $sformatf("Read %08h, valid is %b, err is %b, empty is %b", rdata, rvalid, rerr, empty), UVM_NONE);
    @rcb;
  endtask
  
  task burst_read (input integer unsigned n);
    @rcb;
    rcb.ren <= 1'b1;
    for (integer unsigned i = 0; i < n; ++i) begin
      @rcb;
      `uvm_info("tb_top", $sformatf("%0d: Read %08h, valid is %b, err is %b, empty is %b", i, rdata, rvalid, rerr, empty), UVM_NONE);
    end
    rcb.ren <= 1'b0;
    @rcb;
  endtask
             
endinterface

