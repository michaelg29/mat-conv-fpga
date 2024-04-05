
`include "uvm_macros.svh"

import uvm_pkg::*;

// testcase exercising valid kernel command and payload
class tb_cluster_kernel_size_subject_no_pad 
  #(int KERNEL_SIZE = 5, 
    int FIFO_WIDTH = 8,
    int NUM_ROWS = 5,
    int NUM_COLS = 5,
    parameter COMPUTE_LATENCY = 6) 
    extends mat_conv_tc;

  // virtual interfacepixel
  virtual cluster_if vif;

  // clock period definition
  time MACCLK_PER;

  int num_additional_cycles_shifts;

   // local params
  localparam PADDING = (KERNEL_SIZE-1)/2;

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
    logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] image;
    logic [NUM_ROWS-2*PADDING-1:0][NUM_COLS-2*PADDING-1:0][7:0] imconv;

    logic sign = 1'b0;
    int track_col = 0;

    `uvm_info("tb_cluster_kernel_size_subject_no_pad", "Executing testcase", UVM_NONE);

    @(posedge vif.i_clk);

    // Generate kernel and load it
    kernel = vif.kernel_gen();
    vif.load_kernel(kernel, sign);

    // Generate image
    image = vif.image_gen_nopad();

    //Calculate convolution result (unsigned)
    imconv = vif.image_conv_nopad(image, kernel, sign);

    vif.display_conv_nopad(image, kernel, imconv);


    @(posedge vif.i_clk);
    vif.i_waddr <= 0;

    //Change values on falling edge (problems when doing rising edge)
    @(negedge vif.i_clk);

    vif.i_is_subj <= 1;
    for (int row = 0 ; row < NUM_ROWS ; row++) begin
      track_col = 0;
      for (int col = 0 ; col < NUM_COLS ; col+=FIFO_WIDTH) begin

        vif.i_new_pkt <= 1;
        if(col == 0) begin //first groups: load in parallel
          vif.i_discont <= 1;

          //Image size is assumed to be a multiple of 128 (FIFO_WIDTH aligned). Always an additional 3 clock cycles delay
          num_additional_cycles_shifts = FIFO_WIDTH-KERNEL_SIZE-1;
        end else begin //other groups: load serially
          vif.i_discont <= 0;
          
          //Shift until all pixels have been seen
          num_additional_cycles_shifts = FIFO_WIDTH;
        end

        vif.i_pkt <= image[row][col +: FIFO_WIDTH]; //args must be multiple of FIFO_WIDTH
        
        @(negedge vif.i_clk);
        vif.check_output_nopad(row, track_col, imconv);
        track_col += 1;
        vif.i_new_pkt <= 0;

        for (int i = 0; i <  num_additional_cycles_shifts; i++) begin

          //Check output. Results start appearing at 4th row
          //Also a compute latency of COMPUTE_LATENCY cycles
          @(negedge vif.i_clk);
          vif.check_output_nopad(row, track_col, imconv);
          track_col += 1;
        end
      end


      vif.i_end_of_row <= 1;
      @(negedge vif.i_clk);
      vif.check_output_nopad(row, track_col, imconv);
      track_col += 1;
      vif.i_end_of_row <= 0;

    end
    vif.i_new_pkt <= 0;


    for (int i = 0 ; i < COMPUTE_LATENCY ; i++) begin
      @(negedge vif.i_clk);
      vif.check_output_nopad(NUM_ROWS-1, track_col, imconv);
      track_col += 1;
    end


    //`ASSERT_EQ(vif.addr, 3'b000, %3b);
    //`ASSERT_EQ(vif.payload_done, 1'b0, %b);
    @(negedge vif.i_clk);

  endtask // run

endclass // tb_cluster_kernel_size_subject_no_pad