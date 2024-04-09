
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising XXX
class tb_template_tc extends mat_conv_tc;

  // virtual interface
  //virtual input_fsm_if vif;

  // clock period definition
  time MACCLK_PER;

  // constructor to attach interface to DUT
  function new(/*virtual input_fsm_if vif, */time MACCLK_PER);
    //this.vif = vif;
    this.MACCLK_PER = MACCLK_PER;
  endfunction // new

  task automatic run;

    `uvm_info("tb_template_tc", "Executing testcase", UVM_NONE);

  endtask // run

endclass // tb_template_tc
