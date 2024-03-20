
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid kernel command and payload
class tb_cluster_load_kernel extends mat_conv_tc;

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
    int unsigned addr;

    `uvm_info("tb_cluster_load_kernel", "Executing testcase", UVM_NONE);

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

    `ASSERT_EQ(vif.addr, 3'b000, %3b);

    `ASSERT_EQ(vif.payload_done, 1'b0, %b);
    #(MACCLK_PER);

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_cluster_load_kernel