
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid subject command and payload
class tb_input_fsm_valid_subj extends mat_conv_tc;

  // virtual interface
  virtual input_fsm_if vif;

  time MACCLK_PER;

  // constructor
  function new(virtual input_fsm_if vif, time MACCLK_PER);
    this.vif = vif;
    this.MACCLK_PER = MACCLK_PER;
  endfunction // new

  task automatic run;

    `uvm_info("tb_input_fsm_valid_subj", "Executing testcase", UVM_NONE);

    #(MACCLK_PER);

    vif.rx_pkt = 1'b1;
    vif.rx_addr = 8'h80;
    vif.rx_data = 64'h00000000BEEFCAFE;

    #(MACCLK_PER);
    vif.rx_pkt = 1'b0;

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_input_fsm_valid_subj
