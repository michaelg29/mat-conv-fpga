`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 3, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_cluster_kernel_size_subject_no_pad", // Name of test case to run
        parameter ROUNDING=3'b100
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    reg i_clk;
    logic i_newrow;
    logic i_is_kern;
    logic i_cmd_kern_signed;
    logic i_is_subj;
    logic i_new_pkt;
    logic i_discont;
    logic [FIFO_WIDTH-1:0][7:0] i_pkt; //input pixels from FIFO and/or buffered pixels
    logic [7:0] o_pixel;
    logic o_out_rdy;

    parameter UNSIGNED_UPPER_BOUND = 12'b111111111111;
    parameter SIGNED_UPPER_BOUND = 12'b011111111111;
    parameter SIGNED_LOWER_BOUND = 12'b100000000000;

    //========================================
    // Clocks
    //========================================
    const int clk_period = 200; //ns (5MHz)

    initial begin
        i_clk = 0;
    end

    always #(clk_period / 2) begin
        i_clk <= ~i_clk;
    end


    //========================================
    // DUT
    //========================================
    cluster DUT(
        .i_clk(i_clk),
        .i_newrow(i_newrow),
        .i_is_kern(i_is_kern),
        .i_cmd_kern_signed(i_cmd_kern_signed),
        .i_is_subj(i_is_subj),
        .i_new_pkt(i_new_pkt),
        .i_discont(i_discont),
        .i_pkt(i_pkt),
        .o_out_rdy(o_out_rdy), //TODO remove
        .o_pixel(o_pixel)
    );


    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_cluster_load_kernel",
        "tb_cluster_load_kernel_block",
        "tb_cluster_kernel_size_subject_no_pad"
        //TODO
    };

    initial begin

        //Loop through all possible test cases
        foreach (TEST_CASES[i]) begin

            //If test case, run it
            if(!uvm_re_match(TC, TEST_CASES[i])) begin

                $display("===> Running Test '%s' for %i iterations", TEST_CASES[i], NUM_REPS);

                for (int j = 0 ; j < NUM_REPS ; j++) begin

                    `uvm_info("tb_top", $sformatf("Iteration %d", j), UVM_NONE);

                    `uvm_info("tb_top", "Resetting DUT", UVM_NONE);
                    reset_dut(i_clk, TODO);

                    case (i+1)
                        1 : begin      
                            test1(
                                .i_clk(i_clk),
                                .i_newrow(i_newrow),
                                .i_is_kern(i_is_kern),
                                .i_cmd_kern_signed(i_cmd_kern_signed),
                                .i_is_subj(i_is_subj),
                                .i_new_pkt(i_new_pkt),
                                .i_discont(i_discont),
                                .i_pkt(i_pkt),
                                .o_pixel(o_pixel)
                            );
                            end
                        2 : begin
                            test2(
                                .i_clk(i_clk),
                                .i_newrow(i_newrow),
                                .i_is_kern(i_is_kern),
                                .i_cmd_kern_signed(i_cmd_kern_signed),
                                .i_is_subj(i_is_subj),
                                .i_new_pkt(i_new_pkt),
                                .i_discont(i_discont),
                                .i_pkt(i_pkt),
                                .o_pixel(o_pixel)
                            );
                            end
                        default : $display("WARNING: %d is not a valid task ID", i);
                    endcase

                end

                //Exit loop
                break;
            end

        end
        $finish(0);

    end



    //========================================
    // Functions
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


    //Generate image
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


    //Calculate resulting image
    function logic [NUM_ROWS-1:0][NUM_COLS-1:0][7:0] image_conv;

        input logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] imgen;
        input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen;
        input logic sign;

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


    //Display matrix convolution (only kernel dim)
    function display_conv;
        input logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] imgen;
        input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen;
        input logic [NUM_ROWS-1:0][NUM_COLS-1:0][17:0] imconv;

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

    //========================================
    // Tasks
    //========================================


    /*
        Reset DUT
    */
    task automatic reset_dut;
        ref reg i_clk;    
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;


        logic i_newrow;
        logic i_is_kern;
        logic i_cmd_kern_signed;
        logic i_is_subj;
        logic i_new_pkt;
        logic i_discont;
        logic [FIFO_WIDTH-1:0][7:0] i_pkt; //input pixels from FIFO and/or buffered pixels
        
        begin


            //KRF RESET
            //Load 0s
            i_kernels = '{0};
            i_valid = 1'b1;

            //Reset state machine and outputs
            i_rst = 1'b1;
            @(negedge i_clk);

            i_rst = 1'b0;
            i_valid = 0'b0;
            @(negedge i_clk);
        end
    endtask : reset_dut


    /*
        Load kernel values into KRF
    */
    task automatic load_kernel_values;

        //KRF inputs/outputs
        ref reg i_clk;       
        ref reg i_valid;
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output


        begin
            `uvm_info("tb_top", "Loading Kernel values into KRF", UVM_NONE);
            
            //reset signals
            i_pixels = '{0};
            i_kernels = '{0};
            i_krf_total = '{0};
            krf_total_cvrt = '{0};
            i_en = 0;

            @(negedge i_clk);

            // Enable the core
            i_en = 1;

            i_rst = 1'b1; //reset state machine -> ready to program
            i_valid = 1'b1; //input valid

            for (int i = 0 ; i < NUM_STATES ; i++) begin

                // Load a row
                //assert(std::randomize(i_kernels)); //NEED LICENSE
                if(i==0) begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end else if (i==1) begin
                    i_kernels = 64'h0123456789101112;
                end else if (i==2) begin
                    i_kernels = 64'hBEEF50B3CAFE6688;
                end else begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end
                
                @(negedge i_clk); //input new data / let data appear at output (1 clock cycle)
            end

            i_rst = 1'b0; //done programming
            i_valid = 1'b0; //input invalid

            `uvm_info("tb_top", "Kernel values successfully loaded", UVM_NONE);

        end


    endtask : load_kernel_values



    //========================================
    // Test Cases
    //========================================


    /*
     tb_cluster_load_kernel : Load the kernel into the cluster
     */
    task automatic test1;
        ref reg i_clk;
        ref logic i_newrow;
        ref logic i_is_kern;
        ref logic i_cmd_kern_signed;
        ref logic i_is_subj;
        ref logic i_new_pkt;
        ref logic i_discont;
        ref logic [FIFO_WIDTH-1+KERNEL_SIZE-1:0][7:0] i_pkt; //input pixels from FIFO + buffered pixels
        ref logic [7:0] o_pixel;

        begin
            //TODO
        end

    endtask : test1



    /*
     tb_cluster_load_kernel_block : Load the kernel into the cluster, but assert the i_is_subj to block the operation
     */
    task automatic test2;
        ref reg i_clk;
        ref logic i_newrow;
        ref logic i_is_kern;
        ref logic i_cmd_kern_signed;
        ref logic i_is_subj;
        ref logic i_new_pkt;
        ref logic i_discont;
        ref logic [FIFO_WIDTH-1+KERNEL_SIZE-1:0][7:0] i_pkt; //input pixels from FIFO + buffered pixels
        ref logic [7:0] o_pixel;

        begin
            //TODO
        end

    endtask : test2



    /*
     tb_cluster_kernel_size_subject_no_pad : Load the kernel into the cluster
     */
    task automatic test3;
        ref reg i_clk;
        ref logic i_newrow;
        ref logic i_is_kern;
        ref logic i_cmd_kern_signed;
        ref logic i_is_subj;
        ref logic i_new_pkt;
        ref logic i_discont;
        ref logic [FIFO_WIDTH-1+KERNEL_SIZE-1:0][7:0] i_pkt; //input pixels from FIFO + buffered pixels
        ref logic [7:0] o_pixel;

        begin
            //TODO
        end

    endtask : test3


endmodule