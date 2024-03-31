`timescale 1 ps/ 1 ps

`include "../tb_common/mat_conv.svh"
`include "uvm_macros.svh"

// interface to wrap around the cluster
interface cluster_if #(
  parameter FIFO_WIDTH=8,
  parameter KERNEL_SIZE = 5,
  parameter NUM_ROWS = 5, //subject image row range
  parameter NUM_COLS = 10, //subject image column range
  parameter ROUNDING=3'b100,
  parameter UNSIGNED_UPPER_BOUND = 12'b111111111111,
  parameter SIGNED_UPPER_BOUND = 12'b011111111111,
  parameter SIGNED_LOWER_BOUND = 12'b100000000000
) (
  // clock and reset interface
  input logic i_clk,
  input logic i_rst_n
);

  import uvm_pkg::*;

  logic i_newrow;
  logic i_is_kern;
  logic i_cmd_kern_signed;
  logic i_is_subj;
  logic i_new_pkt;
  logic i_discont;
  logic [FIFO_WIDTH-1:0][7:0] i_pkt; //input pixels from FIFO and/or buffered pixels
  logic [7:0] i_waddr;

  wire [7:0] o_pixel;
  wire o_out_rdy;

  // local params
  localparam PADDING = (KERNEL_SIZE-1)/2;
  localparam NUM_STATES = (KERNEL_SIZE*KERNEL_SIZE - 1)/FIFO_WIDTH + 1; //round up trick


  //========================================
  // Clocked Block
  //========================================
  clocking cb @(posedge i_clk);
    input #0 o_pixel, o_out_rdy;
    output i_newrow, i_is_kern, i_cmd_kern_signed, i_is_subj, i_new_pkt, i_discont, i_pkt, i_waddr;
  endclocking;


  //========================================
  // Helper Functions
  //========================================

  //software implementation of saturator 
  function logic [7:0] saturate;
      input logic [17:0] o_pixel;
      input logic sign;

      logic [7:0] o_pixel_saturate;

      //if signed operation
      if(sign == 1'b1) begin

          // Calculate valid result
          if(signed'(o_pixel) < 0) begin //negative input
              if (signed'(o_pixel) >= signed'(SIGNED_LOWER_BOUND)) begin //if between SIGNED_LOWER_BOUND and 0
                  o_pixel_saturate = o_pixel[11:4];
              end else begin //if below SIGNED_LOWER_BOUND
                  o_pixel_saturate = SIGNED_LOWER_BOUND[11:4];
              end
          end else begin //positive input
              if (signed'(o_pixel) <= signed'(SIGNED_UPPER_BOUND)) begin //if between 0 and SIGNED_UPPER_BOUND
                  o_pixel_saturate = o_pixel[11:4];
              end else begin //if above SIGNED_UPPER_BOUND
                  o_pixel_saturate = SIGNED_UPPER_BOUND[11:4];
              end
          end

      //if unsigned operation
      end else begin

          // Calculate valid result
          if (o_pixel <= UNSIGNED_UPPER_BOUND) begin
              o_pixel_saturate = o_pixel[11:4];
          end else begin
              o_pixel_saturate = UNSIGNED_UPPER_BOUND[11:4];
          end

      end


      return o_pixel_saturate;
  endfunction


  //Generate kernel
  function logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kernel_gen;

      logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen;
          
      for (int row = 0 ; row < KERNEL_SIZE ; row++) begin //for rows
          for (int col = 0 ; col < KERNEL_SIZE ; col++) begin //for columns
              kgen[row][col] = signed'(row+col-col*col);
          end
      end

      return kgen;
  endfunction 


  //Generate image with padding
  function logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] image_gen;

      logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] imgen;

      //first and last rows are padding rows
      for (int row = 0 ; row < PADDING ; row++) begin
          imgen[row] = 0;
          imgen[NUM_ROWS+2*PADDING-row-1] = 0;
      end 

      for (int row = PADDING ; row < NUM_ROWS+PADDING ; row++) begin //for rows (no padding)
          for (int col = 0 ; col < NUM_COLS+2*PADDING ; col++) begin //for columns + padding

              /*
              if((col >= NUM_COLS)) begin //last columns are padding columns (equivalent to padding beginning + end of rows)
                  imgen[row][col] = 0;
              end else begin
                  imgen[row][col] = row+col+2; //+2 to get same matrix as below
              end
              */

              if((col >= NUM_COLS+PADDING) || (col < PADDING)) begin //first and last columns are padding columns
                  imgen[row][col] = 0;
              end else begin
                  imgen[row][col] = unsigned'(row+col+col*col);
              end

          end
      end

      return imgen;
  endfunction



  //Generate image without padding
  function logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] image_gen_nopad;

      logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] imgen;

      for (int row = 0 ; row < NUM_ROWS ; row++) begin //for rows
          for (int col = 0 ; col < NUM_COLS ; col++) begin //for columns 
                imgen[row][col] = unsigned'(row+col+col*col);
          end
      end

      return imgen;
  endfunction


  //Calculate resulting image
  function logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] image_conv(
      input logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] imgen,
      input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen,
      input logic sign
  );
      logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] imconv;
      static int res = 0;
      static int subres = 0;

      for (int row = 0 ; row < NUM_ROWS ; row++) begin
          for (int col = 0 ; col < NUM_COLS ; col++) begin

              //Reset result
              res = 0;

              //Calculate pixel
              for (int krow = 0 ; krow < KERNEL_SIZE ; krow++) begin //for rows
                  subres = signed'(res) + ROUNDING;
                  for (int kcol = 0 ; kcol < KERNEL_SIZE ; kcol++) begin //for columns
                      subres += signed'(kgen[krow][kcol]) * signed'({1'b0 , imgen[row+krow][col+kcol]});
                  end
                  res = signed'(subres[20:3]);
              end

              //Apply saturation
              imconv[row][col] = signed'(saturate(res, sign));
          end
      end

      return imconv;

  endfunction



  //Calculate resulting image
  function logic [NUM_ROWS-2*PADDING-1:0][NUM_COLS-2*PADDING-1:0][7:0] image_conv_nopad(
      input logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] imgen,
      input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen,
      input logic sign
  );
      logic [NUM_ROWS-2*PADDING-1:0][NUM_COLS-2*PADDING-1:0][7:0] imconv;
      static int res = 0;
      static int subres = 0;

      for (int row = 0 ; row < NUM_ROWS-2*PADDING ; row++) begin
          for (int col = 0 ; col < NUM_COLS-2*PADDING ; col++) begin

              //Reset result
              res = 0;

              //Calculate pixel
              for (int krow = 0 ; krow < KERNEL_SIZE ; krow++) begin //for rows
                  subres = signed'(res) + ROUNDING;
                  for (int kcol = 0 ; kcol < KERNEL_SIZE ; kcol++) begin //for columns
                      subres += signed'(kgen[krow][kcol]) * signed'({1'b0 , imgen[row+krow][col+kcol]});
                  end
                  res = signed'(subres[20:3]);
              end

              //Apply saturation
              imconv[row][col] = signed'(saturate(res, sign));
          end
      end

      return imconv;

  endfunction


  //Display matrix convolution (only kernel dim)
  function display_conv(
      input logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] imgen,
      input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen,
      input logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] imconv
  );

      static string s = "";

      //Display kernel
      $display("Kernel");
      for (int row = 0 ; row < KERNEL_SIZE ; row++) begin //for rows

          s = $sformatf("Row %d: ", row);
          for (int col = 0 ; col < KERNEL_SIZE ; col++) begin //for columns
              s = $sformatf("%s %d ", s, signed'(kgen[row][col]));
          end

          $display("%s",s);
      end

      //Display input image
      $display("Input Image");
      for (int row = 0 ; row < NUM_ROWS+2*PADDING ; row++) begin //for rows

          s = $sformatf("Row %d: ", row);
          for (int col = 0 ; col < NUM_COLS+2*PADDING ; col++) begin //for columns
              s = $sformatf("%s %d ", s, imgen[row][col]);
          end

          $display("%s",s);
      end


      //Display output image
      $display("Output Image");
      for (int row = 0 ; row < NUM_ROWS ; row++) begin //for rows

          s = $sformatf("Row %d: ", row);
          for (int col = 0 ; col < NUM_COLS ; col++) begin //for columns
              s = $sformatf("%s %d ", s, signed'(imconv[row][col]));
          end

          $display("%s",s);
      end

  endfunction



  //Display matrix convolution (only kernel dim)
  function display_conv_nopad(
      input logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] imgen,
      input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen,
      input logic [NUM_ROWS-2*PADDING-1:0][NUM_COLS-2*PADDING-1:0][7:0] imconv
  );

      static string s = "";

      //Display kernel
      $display("Kernel");
      for (int row = 0 ; row < KERNEL_SIZE ; row++) begin //for rows

          s = $sformatf("Row %d: ", row);
          for (int col = 0 ; col < KERNEL_SIZE ; col++) begin //for columns
              s = $sformatf("%s %d ", s, signed'(kgen[row][col]));
          end

          $display("%s",s);
      end

      //Display input image
      $display("Input Image");
      for (int row = 0 ; row < NUM_ROWS ; row++) begin //for rows

          s = $sformatf("Row %d: ", row);
          for (int col = 0 ; col < NUM_COLS ; col++) begin //for columns
              s = $sformatf("%s %d ", s, imgen[row][col]);
          end

          $display("%s",s);
      end


      //Display output image
      $display("Output Image");
      for (int row = 0 ; row < NUM_ROWS-2*PADDING ; row++) begin //for rows

          s = $sformatf("Row %d: ", row);
          for (int col = 0 ; col < NUM_COLS-2*PADDING ; col++) begin //for columns
              s = $sformatf("%s %d ", s, signed'(imconv[row][col]));
          end

          $display("%s",s);
      end

  endfunction




    /*
        Reset the cluster signals
    */
    task reset();
        cb.i_newrow <= 0;
        cb.i_is_kern <= 0;
        cb.i_cmd_kern_signed <= 0;
        cb.i_is_subj <= 0;
        cb.i_new_pkt <= 0;
        cb.i_discont <= 0;
        cb.i_pkt <= 0;
        cb.i_waddr <= 0;
        @cb;
    endtask;

    /*
        Load kernel values into KRF
    */
    task automatic load_kernel(
        input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0]  kernel, //input kernel
        input logic sign = 1'b1
    );

        automatic logic [3:0][FIFO_WIDTH-1:0][7:0] kernel_convert; // Convert kernel to load row by row


        //Map kernel to load row by row
        kernel_convert[0] = {kernel[1][2:0], kernel[0]};
        kernel_convert[1] = {kernel[3][0:0], kernel[2], kernel[1][4:3]};
        kernel_convert[2] = {kernel[4][3:0], kernel[3][4:1]};
        kernel_convert[3] = {{7{0}},kernel[4][4:4]};


        begin
            `uvm_info("tb_top", "Loading Kernel values into KRF", UVM_NONE);

            cb.i_is_subj <= 1'b0; //not a subject
            cb.i_is_kern <= 1'b1; //is the kernel
            cb.i_cmd_kern_signed <= sign;
            @cb;

            for (int i = 0 ; i < NUM_STATES ; i++) begin
                cb.i_new_pkt <= 1'b1; //input valid
                cb.i_pkt <= kernel_convert[i];                
                @cb; //input new data / let data appear at output (1 clock cycle)

                cb.i_new_pkt <= 1'b0; //input invalid
                for (int j = 0 ; j < 3 ; j++) @cb;
                
            end

            cb.i_is_kern <= 1'b0; //done programming
            cb.i_new_pkt <= 1'b0; //input invalid
            cb.i_pkt <= '{0};
            @cb;

            `uvm_info("tb_top", "Kernel values successfully loaded", UVM_NONE);

        end


    endtask : load_kernel


endinterface // input_fsm_if