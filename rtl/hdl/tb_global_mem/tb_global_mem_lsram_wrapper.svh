class tb_global_mem_lsram_wrapper;

static task automatic run_task(
  // port A input
  time             ACLK_PER,
  ref logic        A_CLK,
  ref logic [10:0] A_ADDR,
  ref logic [17:0] A_DIN,
  ref logic        A_WEN,
  ref logic        A_REN,

  // port A output wires
  ref logic  [17:0] A_DOUT,

  // port B input
  time             BCLK_PER,
  ref logic        B_CLK,
  ref logic [10:0] B_ADDR,
  ref logic [17:0] B_DIN,
  ref logic        B_WEN,
  ref logic        B_REN,

  // port B output wires
  ref logic  [17:0] B_DOUT
  );

  `uvm_info("tb_global_mem_lsram_wrapper", "Running testcase lsram_wrapper", UVM_NONE);

  A_ADDR = '0;
  A_DIN  = 18'h0BEEF;
  A_WEN  = 1'b1;
  #(ACLK_PER);
  A_WEN  = 1'b0;

  #(5*ACLK_PER);
  A_REN  = 1'b1;
  #(ACLK_PER);
  A_REN  = 1'b0;
  #(10*ACLK_PER);

endtask // run_task

endclass // tb_global_mem_lsram_wrapper