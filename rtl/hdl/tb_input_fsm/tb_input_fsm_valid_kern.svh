
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid kernel command and payload
class tb_input_fsm_valid_kern extends mat_conv_tc;

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

    `uvm_info("tb_input_fsm_valid_kern", "Executing testcase", UVM_NONE);

    #(MACCLK_PER);

    // send valid command
    vif.send_cmd(
      30'h3ABCDEF, '0, '1, // cmd
      32'h00100055,        // size
      32'hABCD0000,        // tx_addr
      '0                   // trans_id
    );

    // spin one cycle
    #(MACCLK_PER);

    // check cluster control output
    `ASSERT_EQ(vif.cmd_kern, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b1, %b);
    #(MACCLK_PER);

    // check global status output
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
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
    vif.rx_pkt = 1'b0;
    #(MACCLK_PER);

    // check global status output
    `ASSERT_EQ(vif.write_blank_en, 1'b0, %b);
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b1, %b);
    `ASSERT_EQ(vif.eor, 1'b0, %b);
    `ASSERT_EQ(vif.prepad_done, 1'b0, %b);
    `ASSERT_EQ(vif.payload_done, 1'b1, %b);
    #(4*MACCLK_PER);

    // check output after arbitrary wait
    `ASSERT_EQ(vif.payload_done, 1'b1, %b); // TODO confirm payload_done is held high

    // Output FSM "completes transmission"
    vif.res_written = 1'b1;
    #(2*MACCLK_PER);

    // check output for status
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.addr, 3'b100, %3b);
    `ASSERT_EQ(vif.wen, 1'b1, %b);
    `ASSERT_EQ(vif.wdata[4:0], 5'h0, %08x); // only care about status field (5 LSBs)
    #(MACCLK_PER);

    // check reset output
    `ASSERT_EQ(vif.write_blank_en, 1'b0, %b);
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.ren, 1'b0, %b);
    `ASSERT_EQ(vif.wen, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b0, %b);
    `ASSERT_EQ(vif.eor, 1'b0, %b);
    `ASSERT_EQ(vif.prepad_done, 1'b0, %b);
    `ASSERT_EQ(vif.payload_done, 1'b0, %b);
    #(MACCLK_PER);

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_input_fsm_valid_kern
