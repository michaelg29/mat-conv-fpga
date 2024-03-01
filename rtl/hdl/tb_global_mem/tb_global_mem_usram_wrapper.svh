class tb_global_mem_usram_wrapper;

static task automatic run_task(
  // port A input
  time             ACLK_PER,
  ref logic        A_CLK,
  ref logic [10:0] A_ADDR,
  ref logic        A_REN,

  // port A output wires
  ref logic [17:0] A_DOUT,

  // port B input
  time             BCLK_PER,
  ref logic        B_CLK,
  ref logic [10:0] B_ADDR,
  ref logic        B_REN,

  // port B output wires
  ref logic [17:0] B_DOUT,

  // port C input
  time             CCLK_PER,
  ref logic        C_CLK,
  ref logic [10:0] C_ADDR,
  ref logic [17:0] C_DIN,
  ref logic        C_WEN
  );

  `uvm_info("tb_global_mem_usram_wrapper", "Running testcase usram_wrapper", UVM_NONE);

  C_ADDR = '0;
  C_DIN = 18'h3BEEF;
  C_WEN = 1'b1;
  #(CCLK_PER);
  C_WEN = 1'b0;
  #(3*CCLK_PER);

  @(posedge B_CLK);
  #(BCLK_PER);
  B_ADDR = '0;
  B_REN = 1'b1;
  #(BCLK_PER);
  B_REN = 1'b0;
  #(3*BCLK_PER);

  @(posedge A_CLK);
  #(ACLK_PER);
  A_ADDR = '0;
  A_REN = 1'b1;
  #(ACLK_PER);
  A_REN = 1'b0;
  #(2*ACLK_PER);

endtask

endclass