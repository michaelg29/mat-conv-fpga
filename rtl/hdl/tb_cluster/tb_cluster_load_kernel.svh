
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid kernel command and payload
class tb_cluster_load_kernel
  #(int KERNEL_SIZE = 5) 
    extends mat_conv_tc;

  // virtual interface
  virtual cluster_if vif;

  // clock period definition
  time MACCLK_PER;

  // constructor
  function new(virtual cluster_if vif, time MACCLK_PER);
    this.vif = vif;
    this.MACCLK_PER = MACCLK_PER;
  endfunction // new

  task automatic run;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kernel;

    `uvm_info("tb_cluster_load_kernel", "Executing testcase", UVM_NONE);

    @(posedge vif.i_clk);

    // Generate kernel and load it
    kernel = vif.kernel_gen();
    vif.load_kernel(kernel);

    @(posedge vif.i_clk);

  endtask // run

endclass // tb_cluster_load_kernel