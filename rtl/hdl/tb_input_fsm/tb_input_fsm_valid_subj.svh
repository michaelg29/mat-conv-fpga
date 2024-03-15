
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid subject command and payload
class tb_input_fsm_valid_subj extends mat_conv_tc;

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
    int unsigned addr;

    `uvm_info("tb_input_fsm_valid_subj", "Executing testcase", UVM_NONE);

    #(MACCLK_PER);

    // send valid command
    vif.send_cmd(
      30'h2AF38000, '1, '0, // cmd
      32'h1FB343AF,         // size
      32'hABCD0000,         // tx_addr
      32'h00000001          // trans_id
    );

    // spin one cycle
    #(MACCLK_PER);

    // check cluster control output
    `ASSERT_EQ(vif.cmd_kern, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b0, %b);
    #(MACCLK_PER);

    // check global status output
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.addr, 3'b000, %3b);
    `ASSERT_EQ(vif.wen, 1'b0, %b);
    #(MACCLK_PER);

    // send payload
    addr = 0;
    for (int unsigned i = 0; i < 4; ++i) begin
      vif.rx_pkt = 1'b1;
      vif.rx_addr = addr;
      #(MACCLK_PER);
      addr += 8;
    end

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_input_fsm_valid_subj
