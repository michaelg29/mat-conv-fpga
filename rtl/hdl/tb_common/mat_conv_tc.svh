
`include "uvm_macros.svh"

import uvm_pkg::*;

// parent class for testcases
class mat_conv_tc;

  // constructor
  function new();

  endfunction // new

  task automatic run;
    `uvm_error("mat_conv_tc", "No testcase defined");
  endtask // run

endclass // mat_conv_tc