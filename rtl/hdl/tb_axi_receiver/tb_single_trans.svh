
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase single AXI transaction
class tb_single_trans extends mat_conv_tc;

  // virtual interface
  virtual axi_rx_if vif;

  // clock period definition
  time MACCLK_PER;

  // constructor to attach interface to DUT
  function new(virtual axi_rx_if vif, time MACCLK_PER);
    this.vif = vif;
    this.MACCLK_PER = MACCLK_PER;
  endfunction // new

  task automatic run;

    `uvm_info("tb_single_trans", "Executing testcase", UVM_NONE);

  endtask // run

endclass // tb_single_trans
