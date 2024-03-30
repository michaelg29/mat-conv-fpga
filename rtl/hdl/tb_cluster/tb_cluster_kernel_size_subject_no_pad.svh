
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid kernel command and payload
class tb_cluster_kernel_size_subject_no_pad #(int KERNEL_SIZE = 5) extends mat_conv_tc;

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
    //UNRESOLVED
    //logic [vif.KERNEL_SIZE-1:0][vif.KERNEL_SIZE-1:0][7:0] kernel;
    //logic [vif.KERNEL_SIZE-1:0][vif.KERNEL_SIZE-1:0][7:0] image;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kernel;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] image;
    logic [7:0] pixel;

    `uvm_info("tb_cluster_kernel_size_subject_no_pad", "Executing testcase", UVM_NONE);

    #(MACCLK_PER);

    // Generate kernel and load it
    kernel = vif.kernel_gen();
    vif.load_kernel(kernel);

    // Generate image
    image = vif.image_gen_nopad();

    //Calculate convolution result (unsigned)
    pixel = vif.image_conv_nopad(kernel, image, 0);

    vif.display_conv(image, kernel, pixel);


    //`ASSERT_EQ(vif.addr, 3'b000, %3b);

    //`ASSERT_EQ(vif.payload_done, 1'b0, %b);
    #(MACCLK_PER);

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_cluster_kernel_size_subject_no_pad