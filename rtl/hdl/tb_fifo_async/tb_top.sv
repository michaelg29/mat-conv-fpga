`timescale 1 ps/ 1 ps
`define WCLK_PER_PS 15625 // 64MHz
`define RCLK_PER_PS 4000  // 250MHz

`include "uvm_macros.svh"

module tb_top();

import uvm_pkg::*;

// generics
localparam integer ADDR_WIDTH = 5;
localparam integer W_EL = 8;
localparam integer N_IN_EL = 8;
localparam integer W_IN = W_EL * N_IN_EL;

// clock and reset
localparam time WCLK_PER = `WCLK_PER_PS * 1ps;
localparam time RCLK_PER = `RCLK_PER_PS * 1ps;
logic w_wclk_dut = 1'b1;
logic w_rclk_dut = 1'b1;
logic rst_n = 1'b0;

// reader clock domain
logic            ren = '0;
wire [W_EL-1:0]  rdata;
wire             empty;
wire             rvalid;
wire             rerr;

// writer clock domain
logic [W_IN-1:0] wdata = '0;
logic            wen = '0;
wire             full;
wire             wvalid;
wire             werr;

// DUT instantiation
fifo_async_multw #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .W_EL(W_EL),
  .N_IN_EL(N_IN_EL),
  .PRIORITY_W(2'b10)
) DUT (
  .i_rst_n  (rst_n),
  
  .i_rclk   (w_rclk_dut),
  .i_ren    (ren),
  .o_rdata  (rdata),
  .o_empty  (empty),
  .o_rvalid (rvalid),
  .o_rerr   (rerr),
  
  .i_wclk   (w_wclk_dut),
  .i_wdata  (wdata),
  .i_wen    (wen),
  .o_full   (full),
  .o_wvalid (wvalid),
  .o_werr   (werr)
);

// Clock generation
always #(WCLK_PER / 2) begin
	w_wclk_dut <= ~w_wclk_dut;
end
always #(RCLK_PER / 2) begin
	w_rclk_dut <= ~w_rclk_dut;
end

initial begin

  logic [W_EL-1:0] wdata_arr[8];
  wdata_arr = '{8'hBE, 8'hEF, 8'hCA, 8'hFE, 8'hDE, 8'hEF, 8'h12, 8'h34};

  #(1ps);

	// code that executes only once
	$display("Running testbench");
	// insert code here --> begin
  #(WCLK_PER);
  rst_n <= 1'b1;
  $display("Done with startup");
    
  fork
    begin // writer
      wdata <= 64'hBEEFCAFEDEEF1234;
      wen <= 1'b1;
      #(1*WCLK_PER);
      wen <= 1'b0;
       `uvm_info("tb_top", $sformatf("Writing %016h, valid is %b, err is %b", wdata, wvalid, werr), UVM_NONE);
    end
    begin // reader
      ren <= 1'b1;
      #(1*WCLK_PER);
      for (int i = 0; i < 4; ++i) begin
        ren <= 1'b1;
        #(1*RCLK_PER);
        `uvm_info("tb_top", $sformatf("Reading %02h, valid is %b, err is %b", rdata, rvalid, rerr), UVM_NONE);
      end
      ren <= 1'b0;
    end
  join
  
  // fork
    // begin // writer
      // wdata <= 64'h89ABCDEF98765432;
      // wen <= 1'b1;
      // #(1*WCLK_PER);
      // wen <= 1'b0;
       // `uvm_info("tb_top", $sformatf("Writing %016h, valid is %b, err is %b", wdata, wvalid, werr), UVM_NONE);
    // end
    // begin // reader
      // #(1*WCLK_PER);
      // ren <= 1'b1;
      // for (int i = 0; i < 12; ++i) begin
        // ren <= 1'b1;
        // #(1*RCLK_PER);
        // `uvm_info("tb_top", $sformatf("Reading %02h, valid is %b, err is %b", rdata, rvalid, rerr), UVM_NONE);
      // end
      // ren <= 1'b0;
    // end
  // join
    
  $display("Resetting");
  rst_n <= 1'b0;
  #(10*WCLK_PER);
  
  $display("Exiting");
  $stop();
end

endmodule
