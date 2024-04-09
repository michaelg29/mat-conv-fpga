
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

    // send payload
    addr = 0;
    for (int unsigned r = 1082; r > 0; r--) begin
      for (int unsigned c = 1920/8; c > 0; c--) begin
        vif.rx_pkt = 1'b1;
        vif.rx_addr = addr;
        #(MACCLK_PER);
        addr = (addr + 8) & 8'h7f; // wrap transfer

        // check write_blank_en towards end of row
        if ((c < 16)) `ASSERT_EQ(vif.write_blank_en, 1'b1, %b);

        // check prepad_done after second row
        if ((r <= 1080)) `ASSERT_EQ(vif.prepad_done, 1'b1, %b);
      end

      // insert blank packet
      `ASSERT_EQ(vif.write_blank_en, 1'b1, %b);
      vif.rx_pkt = 1'b1;
      vif.rx_addr = 8'h01;
      vif.write_blank_ack = 1'b1;
      #(MACCLK_PER);
      vif.write_blank_ack = 1'b0;

      // assert end of row pulses
      vif.rx_pkt = 1'b0;
      `ASSERT_EQ(vif.eor, 1'b1, %b);
      #(MACCLK_PER);
      `ASSERT_EQ(vif.eor, 1'b0, %b);

      // check prepad_done after second row
      if ((r == 1081)) `ASSERT_EQ(vif.prepad_done, 1'b1, %b);

      // ensure write_blank_ensignal is de-asserted
      #(MACCLK_PER);
      `ASSERT_EQ(vif.write_blank_en, 1'b0, %b);
    end

    // check global status output
    `ASSERT_EQ(vif.write_blank_en, 1'b0, %b);
    `ASSERT_EQ(vif.drop_pkts, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_valid, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_err, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_kern, 1'b0, %b);
    `ASSERT_EQ(vif.cmd_subj, 1'b1, %b);
    `ASSERT_EQ(vif.cmd_kern_signed, 1'b0, %b);
    `ASSERT_EQ(vif.eor, 1'b0, %b);
    `ASSERT_EQ(vif.prepad_done, 1'b1, %b);
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
    `ASSERT_EQ(vif.wdata[4:0], 5'h0, %08x);
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

  endtask // run

endclass // tb_input_fsm_valid_subj
