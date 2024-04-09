
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising error during processing
class tb_input_fsm_err_proc extends mat_conv_tc;

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

    `uvm_info("tb_input_fsm_err_proc", "Executing testcase", UVM_NONE);

    #(MACCLK_PER);

    // send valid command
    vif.send_cmd(
      30'h2AF38000, '1, '0, // cmd
      32'h1FB343AF,         // size, 1082x1920 subject, 259680 packets
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
    `ASSERT_EQ(vif.wen, 1'b0, %b);
    #(MACCLK_PER);

    // send 220 payload packets (1760 columns)
    `uvm_info("tb_input_fsm_err_proc", "Sending 220 packets", UVM_NONE);
    addr = 0;
    for (int unsigned i = 0; i < 220; ++i) begin
      vif.rx_pkt = 1'b1;
      vif.rx_addr = addr;
      #(MACCLK_PER);
      addr = (addr + 8) & 8'h7f; // wrap transfer
    end
    `uvm_info("tb_input_fsm_err_proc", "Sent 220 packets", UVM_NONE);

    // raise processing error
    vif.rx_pkt = 1'b1;
    vif.proc_error = 1'b1;
    #(MACCLK_PER);
    vif.proc_error = 1'b0;
    #(MACCLK_PER);

    // check output
    `ASSERT_EQ(vif.drop_pkts, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b1, %b);
    `ASSERT_EQ(vif.addr, 3'b100, %3b);
    `ASSERT_EQ(vif.wen, 1'b1, %b);
    // check status: 0x7EB08281
    // [31:13] cur_pkts - 0x3F584, 259680 - 220 = 259460
    // [12: 5] cur_cols - 0x14, 1920/8 - 220 = 20
    // [ 4: 0] status   - 0x01, MC_STAT_ERR_PROC
    `ASSERT_EQ(vif.wdata, 32'h7EB08281, %08x); // TODO error here
    #(MACCLK_PER);

    // check output
    `ASSERT_EQ(vif.drop_pkts, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b1, %b);
    `ASSERT_EQ(vif.wen, 1'b0, %b);
    #(MACCLK_PER);

    // wait then acknowledge error
    #(5*MACCLK_PER);
    vif.rx_pkt = 1'b0;
    vif.state_reg_pls = 1'b1;
    #(MACCLK_PER);
    vif.state_reg_pls = 1'b0;
    `ASSERT_EQ(vif.ren, 1'b1, %b);
    #(MACCLK_PER);

    // check output
    `ASSERT_EQ(vif.write_blank_en, 1'b0, %b);
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.wen, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b0, %b);
    `ASSERT_EQ(vif.eor, 1'b0, %b);
    `ASSERT_EQ(vif.prepad_done, 1'b0, %b);
    `ASSERT_EQ(vif.payload_done, 1'b0, %b);
    #(MACCLK_PER);

    // send a few packets to check service continuation
    // 5 packets to trigger write_blank_en
    for (int unsigned i = 0; i < 5; ++i) begin
      vif.rx_pkt = 1'b1;
      vif.rx_addr = addr;
      #(MACCLK_PER);
      addr = (addr + 8) & 8'h7f; // wrap transfer
    end
    vif.rx_pkt = 1'b0;
    #(MACCLK_PER);

    // check output
    `ASSERT_EQ(vif.write_blank_en, 1'b1, %b);
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.ren, 1'b0, %b);
    `ASSERT_EQ(vif.wen, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b0, %b);
    `ASSERT_EQ(vif.eor, 1'b0, %b);
    `ASSERT_EQ(vif.prepad_done, 1'b0, %b);
    `ASSERT_EQ(vif.payload_done, 1'b0, %b);
    #(MACCLK_PER);

    // send rest of payload
    vif.rx_pkt = 1'b1;
    vif.rx_addr = 0;
    #((1082*1921-225)*MACCLK_PER);

    // check output
    `ASSERT_EQ(vif.payload_done, 1'b1, %b);
    #(4*MACCLK_PER);
    `ASSERT_EQ(vif.payload_done, 1'b1, %b);

    // Output FSM "completes transmission"
    vif.res_written = 1'b1;
    #(2*MACCLK_PER);

    // check output for all okay status
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.addr, 3'b100, %3b);
    `ASSERT_EQ(vif.wen, 1'b1, %b);
    `ASSERT_EQ(vif.wdata[4:0], 5'h0, %08x);
    #(MACCLK_PER);

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_input_fsm_err_proc
