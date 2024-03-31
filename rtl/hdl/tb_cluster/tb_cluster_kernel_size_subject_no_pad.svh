
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid kernel command and payload
class tb_cluster_kernel_size_subject_no_pad 
  #(int KERNEL_SIZE = 5, 
    int FIFO_WIDTH = 8,
    int NUM_ROWS = 5,
    int NUM_COLS = 5) 
    extends mat_conv_tc;

  // virtual interface
  virtual cluster_if vif;

  // clock period definition
  time MACCLK_PER;

  int num_additional_cycles_shifts;

  // constructor
  function new(virtual cluster_if vif, time MACCLK_PER);
    this.vif = vif;
    this.MACCLK_PER = MACCLK_PER;
  endfunction // new

  task automatic run;
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
    vif.load_kernel(kernel, 1'b1);

    // Generate image
    image = vif.image_gen_nopad();

    //Calculate convolution result (unsigned)
    pixel = vif.image_conv_nopad(image, kernel, 1'b1);

    vif.display_conv_nopad(image, kernel, pixel);


    #(MACCLK_PER);

    vif.i_discont <= 0;
    vif.i_waddr <= 0;

    #(MACCLK_PER);

    vif.i_is_subj <= 1;
    for (int row = 0 ; row < NUM_ROWS ; row++) begin
      vif.i_newrow <= 1;
      for (int col = 0 ; col < NUM_COLS ; col+=FIFO_WIDTH) begin
        vif.i_new_pkt <= 1;

        //vif.i_pkt <= image[row][col :+ FIFO_WIDTH];
        vif.i_pkt <= image[row][KERNEL_SIZE-1:0]; //ONLY FOR THIS
        
        #(MACCLK_PER);
        vif.i_newrow <= 0;

        // Max of FIFO_WIFTH-KERNEL_SIZE additional shifts
        if(NUM_COLS - col*FIFO_WIDTH < FIFO_WIDTH) begin
          // Minimum number of pixels is 5 for a transfer (kernel size), max is FIFO_WIDTH (8)
          num_additional_cycles_shifts = (NUM_COLS - col*FIFO_WIDTH) - KERNEL_SIZE;
        end else begin
          num_additional_cycles_shifts = FIFO_WIDTH-KERNEL_SIZE;
        end

        for (int i = 0; i <  num_additional_cycles_shifts; i++) begin
          vif.i_new_pkt <= 0;
          #(MACCLK_PER);
        end

      end
    end
    vif.i_new_pkt <= 0;


    for (int i = 0 ; i < 10 ; i++) begin
      $display("%i", vif.o_pixel);
      #(MACCLK_PER);
    end


    //`ASSERT_EQ(vif.addr, 3'b000, %3b);

    //`ASSERT_EQ(vif.payload_done, 1'b0, %b);
    #(MACCLK_PER);

    #(3*MACCLK_PER);

  endtask // run

endclass // tb_cluster_kernel_size_subject_no_pad