
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
    
    `uvm_info("tb_top", $sformatf("Wrote %08h, valid is %b, err is %b, full is %b", i_wdata, wvalid, werr, full), UVM_NONE);
    @cb;
  endtask
  
  task read (output [W_EL-1:0] o_rdata);
    cb.ren <= 1'b1;
    @cb;
    cb.ren <= 1'b0;
    while (!(cb.rvalid == 1'b0 && cb.rerr == 1'b0)) @cb;
    o_rdata  <= cb.rdata;
    
    `uvm_info("tb_top", $sformatf("Read %08h, valid is %b, err is %b, empty is %b", rdata, rvalid, rerr, empty), UVM_NONE);
    @cb;
  endtask
  
  task burst_read (input integer unsigned n);
    @cb;
    cb.ren <= 1'b1;
    for (integer unsigned i = 0; i < n; ++i) begin
      @cb;
      `uvm_info("tb_top", $sformatf("%0d: Read %08h, valid is %b, err is %b, empty is %b", i, rdata, rvalid, rerr, empty), UVM_NONE);
    end
    cb.ren <= 1'b0;
    @cb;
  endtask
             
endinterface
