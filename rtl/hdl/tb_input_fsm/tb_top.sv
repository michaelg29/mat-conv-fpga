`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "../tb_common/mat_conv_tc.svh"
`include "uvm_macros.svh"

module tb_top #(
  parameter string TC="tb_input_fsm_valid_kern" // Name of test case to run
);

import tb_input_fsm_pkg::*;
import uvm_pkg::*;

// generics

// clock and reset
time MACCLK_PER = `MACCLK_PER_PS * 1ps;
logic w_macclk_dut = 1'b1;
logic rst_n = 1'b0;
logic por_n = 1'b1;

`define ASSERT_EQ(a, b, format="%08h") if (a != b) `uvm_error("tb_top", $sformatf(`"Unexpected data in ``a``. Expected format, got format`", b, a))

input_fsm_if #(
  .DW(64)
) intf (
  .macclk(w_macclk_dut),
  .rst_n(rst_n),
  .por_n(por_n)
);

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
  .i_rx_pkt(intf.rx_pkt),
  .i_rx_addr(intf.rx_addr),
  .i_rx_data(intf.rx_data),

  // signals to and from AXI Receiver
  .i_write_blank_ack(intf.write_blank_ack),
  .o_write_blank_en(intf.write_blank_en),
  .o_drop_pkts(intf.drop_pkts),

  // signals to and from Command Buffer
  .i_rdata(intf.rdata),
  .i_rvalid(intf.rvalid),
  .i_state_reg_pls(intf.state_reg_pls),
  .o_addr(intf.addr),
  .o_ren(intf.ren),
  .o_wen(intf.wen),
  .o_wdata(intf.wdata),

  // global status signals
  .i_proc_error(intf.proc_error),
  .i_res_written(intf.res_written),
  .o_cmd_valid(intf.cmd_valid),
  .o_cmd_err(intf.cmd_err),
  .o_cmd_kern(intf.cmd_kern),
  .o_cmd_subj(intf.cmd_subj),
  .o_cmd_kern_signed(intf.cmd_kern_signed),
  .o_eor(intf.eor),
  .o_prepad_done(intf.prepad_done),
  .o_payload_done(intf.payload_done)
);

// Clock generation
always #(MACCLK_PER / 2) begin
	w_macclk_dut <= ~w_macclk_dut;
end

// instantiate testcase
generate
  case (TC)
    "tb_input_fsm_err_cmd":
    begin: tc
      tb_input_fsm_err_cmd tc = new(intf, MACCLK_PER);
    end
    "tb_input_fsm_err_proc":
    begin: tc
      tb_input_fsm_err_proc tc = new(intf, MACCLK_PER);
    end
    "tb_input_fsm_valid_kern":
    begin: tc
      tb_input_fsm_valid_kern tc = new(intf, MACCLK_PER);
    end
    "tb_input_fsm_valid_subj":
    begin: tc
      tb_input_fsm_valid_subj tc = new(intf, MACCLK_PER);
    end
    default:
    begin: tc
      mat_conv_tc tc = new();
    end // tc
  endcase // TC
endgenerate

initial begin

	// startup sequence
	`uvm_info("tb_top", "Running testbench", UVM_NONE);
  #(MACCLK_PER+1ps);
  rst_n <= 1'b1;
  `uvm_info("tb_top", "Completed startup", UVM_NONE);
  #(MACCLK_PER);

  // run testcase
  tc.tc.run();

  // reset sequence
  #(MACCLK_PER);
  rst_n <= 1'b0;
  #(5*MACCLK_PER);

  `uvm_info("tb_top", "Exiting", UVM_NONE);
  $stop();
end

endmodule
