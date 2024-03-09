
package tb_template_pkg;

  import uvm_pkg::*;

  // UVM include
  `include "uvm_macros.svh"

  // utility classes
  `include "../tb_common/mat_conv.svh"
  `include "../tb_common/mat_conv_tc.svh"

  // testcases
  `include "tb_single_trans.svh"

endpackage // tb_axi_rx_pkg
