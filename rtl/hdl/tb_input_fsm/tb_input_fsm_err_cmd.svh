
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising error in the command
class tb_input_fsm_err_cmd extends mat_conv_tc;

  // virtual interface
  virtual input_fsm_if vif;

  // clock period definition
  time MACCLK_PER;

  // constructor
  function new(virtual input_fsm_if vif, time MACCLK_PER);
    this.vif = vif;
    this.MACCLK_PER = MACCLK_PER;
  endfunction // new

  task automatic run;

    `uvm_info("tb_input_fsm_err_cmd", "Executing testcase", UVM_NONE);

    #(MACCLK_PER);

    // send command
    vif.send_cmd(
      '0, '0, '0, // cmd
      '0,         // size
      '0,         // tx_addr
      '0,         // trans_id
      '0,         // s_key
      '0,         // e_key
      1'b1        // invalid_chksum
    );

    // spin one cycle
    vif.rx_pkt = 1'b0;
    #(MACCLK_PER);

    // check cluster control output
    `ASSERT_EQ(vif.cmd_kern, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b0, %b);
    #(MACCLK_PER);

    // check global status output
    `ASSERT_EQ(vif.drop_pkts, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b1, %b);
    `ASSERT_EQ(vif.addr, 3'b100, %3b);
    `ASSERT_EQ(vif.wen, 1'b1, %b);
    `ASSERT_EQ(vif.wdata[4:0], 5'h0E, %02x);
    #(MACCLK_PER);

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_input_fsm_err_cmd