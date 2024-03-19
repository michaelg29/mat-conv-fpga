`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 2, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_cluster_carry_io_mem_pipeline", // Name of test case to run

        parameter ROUNDING = 3'b100,
        parameter WRITE_VALID_DELAY = 5, //delay between valid address and valid input data
        parameter READ_DELAY = 2, //delay between valid address and valid output data of CMC
        parameter CORE_DELAY = 2, //delay from input to output of core
        parameter NUM_PIXEL_REPS = 2,

        parameter NUM_ROWS = 5, //subject image row range
        parameter NUM_COLS = 10 //subject image column range
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    
    reg i_clk;

    /*
    CMC signals
    */
    reg i_en;
    logic i_val;
    logic [10:0] i_addr;
    logic [KERNEL_SIZE-1:0][17:0] i_core;
    logic [KERNEL_SIZE-1:0][17:0] o_core;
    logic [17:0] o_pixel;


    /*
    Cores signals
    */
    //reg i_en; //shared by all cores
    logic [KERNEL_SIZE-1:0][7:0] i_pixels_cores = 0;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] i_kernels = 0;
    //logic [17:0] i_sub; //connect to CMC 
    //logic [KERNEL_SIZE-1:0][17:0] o_res; //connect to CMC


    /*
    Kernel
    */
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kernel;

    /*
    Image
    */
    localparam PADDING = (KERNEL_SIZE-1)/2;
    logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] image;

    /*
    Result Image
    */
    logic [NUM_ROWS-1:0][NUM_COLS-1:0][17:0] res_image; //resulting image, no saturation


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
    
    //CMC
    cmc #(
        .ECC_EN(1'b0)
    ) cmc_dut (
        .i_clk(i_clk),
        .i_en(i_en),

        .i_val(i_val),
        .i_addr(i_addr),
        .i_core_0(i_core[0]),
        .i_core_1(i_core[1]),
        .i_core_2(i_core[2]),
        .i_core_3(i_core[3]),
        .i_core_4(i_core[4]),

        .o_core_0(o_core[0]),
        .o_core_1(o_core[1]),
        .o_core_2(o_core[2]),
        .o_core_3(o_core[3]),
        .o_core_4(o_core[4]),

        .o_pixel(o_pixel)
    );

    //Always enabled
    assign i_en = 1'b1;


    //Cores
    genvar g;
    generate;
    for(g=0 ; g<KERNEL_SIZE ; g++) begin

        //Connect core
        core #(
            .i_round({41'b0,ROUNDING})
        )
        core_dut(
            .i_clk      (i_clk),
            .i_en       (i_en),
            .i_s0       (i_pixels_cores[0]),
            .i_s1       (i_pixels_cores[1]),
            .i_s2       (i_pixels_cores[2]),
            .i_s3       (i_pixels_cores[3]),
            .i_s4       (i_pixels_cores[4]),

            .i_k0       (i_kernels[g][0]),
            .i_k1       (i_kernels[g][1]),
            .i_k2       (i_kernels[g][2]),
            .i_k3       (i_kernels[g][3]),
            .i_k4       (i_kernels[g][4]),
            .i_sub      (o_core[g]), //CMC o_core_* output
            .o_res      (i_core[g]) //CMC i_core_* input
        );
    end
    endgenerate


    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_cluster_carry_io_mem_pipeline"
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
                    reset_dut(
                        .i_clk(i_clk)
                        );

                    case (i+1)
                        1 : begin      
                            test1(
                                .i_clk(i_clk),

                                //CMC signals
                                .i_val(i_val),
                                .i_addr(i_addr),
                                .i_core(i_core),
                                .o_core(o_core),
                                .o_pixel(o_pixel),

                                //Cores signals
                                .i_pixels_cores(i_pixels_cores),
                                .i_kernels(i_kernels)
                            );
                            end
                        //2 : begin
                        //    test2();
                        //    end
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
    function logic [NUM_ROWS-1:0][NUM_COLS-1:0][17:0] image_conv;

        input logic [NUM_ROWS+2*PADDING-1:0][NUM_COLS+2*PADDING-1:0][7:0] imgen;
        input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kgen;

        logic [NUM_ROWS-1:0][NUM_COLS-1:0][17:0] imconv;
        static int res = 0;
        static int subres = 0;

        for (int row = 0 ; row < NUM_ROWS ; row++) begin
            for (int col = 0 ; col < NUM_COLS ; col++) begin

                //Reset result
                res = 0;

                //Calculate pixel
                for (int krow = 0 ; krow < KERNEL_SIZE ; krow++) begin //for rows
                    subres = res + ROUNDING;
                    for (int kcol = 0 ; kcol < KERNEL_SIZE ; kcol++) begin //for columns
                        subres += signed'(kgen[krow][kcol]) * signed'({1'b0 , imgen[row+krow][col+kcol]});
                    end
                    res = subres[20:3];
                end

                imconv[row][col] = signed'(res);
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
        begin
            //TODO
        end
    endtask : reset_dut


    //========================================
    // Test Cases
    //========================================


    /*
     tb_cluster_carry_io_mem_pipeline : load pixels/kernel values, then check cores and CMC outputs. Includes padding logic
     */
    task automatic test1;

        //Shared inputs
        ref reg i_clk;


        //CMC signals
        ref logic i_val;
        ref logic [10:0] i_addr;
        ref logic [KERNEL_SIZE-1:0][17:0] i_core;
        ref logic [KERNEL_SIZE-1:0][17:0] o_core;
        ref logic [17:0] o_pixel;

        //Cores signals
        ref logic [KERNEL_SIZE-1:0][7:0] i_pixels_cores;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] i_kernels;


        //Expected CMC outputs
        logic [KERNEL_SIZE:0][17:0] o_expected; //o_core_0 to o_core_KERNELSIZE concatenated to o_pixel


        //Result image offsets
        int res_row;
        int res_col;

        begin


            //Generate Kernel
            `uvm_info("tb_top", "Generating kernel", UVM_NONE);
            kernel = kernel_gen();

            //Generate image
            `uvm_info("tb_top", "Generating subject image with padding", UVM_NONE);
            image = image_gen();

            //Calculate result
            `uvm_info("tb_top", "Calculating result", UVM_NONE);
            res_image = image_conv(image, kernel);

            if(VERBOSE) begin
                display_conv(image, kernel, res_image);
            end


            //Load kernel values
            i_kernels = kernel;
            @(negedge i_clk);
            

            // Reset all signals to 0
            i_addr = 0;
            i_pixels_cores = 0;
            i_val = 1'b0;
            @(negedge i_clk);


            //Next inputs are valid
            i_val = 1'b1;

            /*
            NOTE:
            This assumes the whole image is assigned to the cluster
            */

            //Loop through rows of input image
            for (int row = 0 ; row < NUM_ROWS+2*PADDING ; row++) begin

                //Reset address counter for new row
                i_addr = 0;

                for (int col = 0 ; col < NUM_COLS ; col++) begin //for columns

                    //Address is in same row
                    if(col > READ_DELAY) begin //input to cores is only valid after READ_DELAY clock cycles, need to wait
                        i_pixels_cores = image[row][col-READ_DELAY-1 +: KERNEL_SIZE];

                    //Address is in next row
                    end else if(row > 0) begin //if give input of previous row, but address of new row
                        i_pixels_cores = image[row-1][col+NUM_COLS-READ_DELAY-1 +: KERNEL_SIZE];
                    end
                    @(negedge i_clk);

                    //Increment address by 1
                    i_addr++;


                    /*
                    Check o_pixel
                    */
                    //if((addr >= WRITE_VALID_DELAY)) begin //if first valid o_pixel of the row
                        if((row*NUM_COLS+col) >= ((KERNEL_SIZE-1)*NUM_COLS+WRITE_VALID_DELAY)) begin //if valid outputs

                            //Calculate effective offsets
                            if(col >= WRITE_VALID_DELAY) begin //Address is in same row
                                res_row = row-(KERNEL_SIZE-1);
                                res_col = col-WRITE_VALID_DELAY;
                            end else begin //Address is in next row
                                res_row = row-(KERNEL_SIZE-1)-1;
                                res_col = col+NUM_COLS-WRITE_VALID_DELAY;
                            end

                            if(VERBOSE) begin
                                $display("R%d:C%d -> out: %d , expect: %d", res_row, res_col, o_pixel, signed'(res_image[res_row][res_col]));
                            end
                            if(signed'(res_image[res_row][res_col]) != o_pixel) begin
                                `uvm_error("tb_top", $sformatf("Test failed at addr = 0x%X, row %d, col %d\noutput = %d ; expected = %d",i_addr,res_row,res_col,o_pixel,signed'(res_image[res_row][res_col])));
                            end

                        end
                    //end

                end
            end

            //Next inputs are NOT valid
            i_val = 1'b0;

            //Loop through all remaining addresses (WRITE_VALID_DELAY clock cycles)
            for (int i = 0 ; i < WRITE_VALID_DELAY ; i++) begin
                @(negedge i_clk);

                res_row = NUM_ROWS-1;
                res_col = NUM_COLS-WRITE_VALID_DELAY+i;

                if(VERBOSE) begin
                    $display("R%d:C%d -> out: %d , expect: %d", res_row, res_col, o_pixel, signed'(res_image[res_row][res_col]));
                end 
                if(signed'(res_image[res_row][res_col]) != o_pixel) begin
                    `uvm_error("tb_top", $sformatf("Test failed at addr = 0x%X, row %d, col %d\noutput = %d ; expected = %d",i_addr,res_row,res_col,o_pixel,signed'(res_image[res_row][res_col])));
                end
            end
            
            @(negedge i_clk);
            @(negedge i_clk);


        end

    endtask : test1


endmodule