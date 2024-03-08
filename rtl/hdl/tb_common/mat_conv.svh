
`ifndef MAT_CONV_SVH
`define MAT_CONV_SVH

`define ACLK_PER_PS 15625 // 64MHz
`define MACCLK_PER_PS 4000  // 250MHz

`define ASSERT_EQ(a, b, format="%08h") if (a != b) `uvm_error("tb_top", $sformatf(`"Unexpected data in ``a``. Expected format, got format`", b, a))

`endif
