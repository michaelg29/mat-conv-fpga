`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 3, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_testcase name", // Name of test case to run

        parameter ROUNDING = 3'b100,
        parameter READ_DELAY = 2 //delay between valid address and valid output data
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    
    reg i_clk;

    /*
    KRF signals
    */
    reg i_valid;
    reg i_rst;
    logic [FIFO_WIDTH-1:0][7:0] i_kernels;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]
    const int NUM_STATES = (KERNEL_SIZE*KERNEL_SIZE - 1)/FIFO_WIDTH + 1; //round up trick
    
    /*
    Cluster feeder
    */
    reg [FIFO_WIDTH-1:0][7:0] i_pixels;
    reg i_new;
    reg i_sel;
    reg [KERNEL_SIZE-1:0][7:0] o_pixels;


    /*
    Cores signals
    */
    reg i_en; //shared by all cores
    logic [KERNEL_SIZE-1:0][7:0] i_pixels_cores; //connect to o_pixels of cluster feeder with one clock cycle delay
    //logic [KERNEL_SIZE-1:0][7:0] i_kernels; //connect to o_kernels of KRF directly
    //logic [17:0] i_sub; //constant 0 for all cores
    logic [KERNEL_SIZE-1:0][17:0] o_res; //output of each core

    // Variables declarations (packed arrays)
    var longint i1 = 0; // 5 pixels
    var longint j1 = 0; // 5 kernel values
    var longint k1 = 0; // sub
    var [KERNEL_SIZE-1:0][43:0] oreg = 0;

    // use time to get 64-bit signed int (only need 40-bits for i and j)
    var longint i;
    var longint j;
    var longint k;


    /*
    Delays
    */
    logic [READ_DELAY-1:0][FIFO_WIDTH-1:0][7:0] pixels_delay; //delays from cluster feeder to cores



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
    
    //KRF
    krf krf_dut(
        .i_clk      (i_clk),
        .i_valid    (i_valid),
        .i_rst      (i_rst),

        .i_data     (i_kernels),
        .o_kr_0     (o_kernels[0]),
        .o_kr_1     (o_kernels[1]),
        .o_kr_2     (o_kernels[2]),
        .o_kr_3     (o_kernels[3]),
        .o_kr_4     (o_kernels[4])
    );


    // Cluster feeder
    cluster_feeder cluster_feeder_dut(
        .i_clk  (i_clk),

        .i_sel  (i_sel),
        .i_new  (i_new),
        
        .i_pixel_0 (i_pixels[0]),
        .i_pixel_1 (i_pixels[1]),
        .i_pixel_2 (i_pixels[2]),
        .i_pixel_3 (i_pixels[3]),
        .i_pixel_4 (i_pixels[4]),
        .i_pixel_5 (i_pixels[5]),
        .i_pixel_6 (i_pixels[6]),
        .i_pixel_7 (i_pixels[7]),
        
        .o_pixel_0 (o_pixels[0]),
        .o_pixel_1 (o_pixels[1]),
        .o_pixel_2 (o_pixels[2]),
        .o_pixel_3 (o_pixels[3]),
        .o_pixel_4 (o_pixels[4])
    );


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

            .i_k0       (o_kernels[g][0]),
            .i_k1       (o_kernels[g][1]),
            .i_k2       (o_kernels[g][2]),
            .i_k3       (o_kernels[g][3]),
            .i_k4       (o_kernels[g][4]),
            .i_sub      ('{0}), //constant 0
            .o_res      (o_res[g])
        );
    end
    endgenerate


    //Delay from cluster feeder output to cores
    assign pixels_delay[0] = o_pixels; //feed into pixels delay pipeline 
    genvar d;
    generate
    for(d=0 ; d<READ_DELAY-1 ; d++) begin
        //Explicit shift registers for delays
        shift_register#(
            .WIDTH(KERNEL_SIZE*8)
        )
        sr(
            .i_clk(i_clk),
            .i_val(pixels_delay[d]),
            .o_val(pixels_delay[d+1])
        );
    end
    endgenerate
    assign i_pixels_cores = pixels_delay[READ_DELAY-1]; //feed output of pixels delay pipeline into cores


    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_testcase name"
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
                    //reset_dut(i_clk, TODO);

                    case (i+1)
                        1 : begin      
                            test1();
                            end
                        2 : begin
                            test2();
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


    /*
        Check the current KRF output to the input values
    */
    function logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_convert;
        input [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total;

        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt;

        krf_total_cvrt[0] = i_krf_total[0][7:3];

        krf_total_cvrt[1] = {i_krf_total[0][2:0], i_krf_total[1][7:6]};

        krf_total_cvrt[2] = i_krf_total[1][5:1];

        krf_total_cvrt[3] = {i_krf_total[1][0:0], i_krf_total[2][7:4]};

        krf_total_cvrt[4] = {i_krf_total[2][3:0], i_krf_total[3][7:7]};
        
        
        if(VERBOSE) begin
            $display("0:i_krf_total = 0x%X ; convert = 0x%X",i_krf_total[0][7:3], krf_total_cvrt[0]);
            $display("1:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[0][2:0], i_krf_total[1][7:6]}, krf_total_cvrt[1]);
            $display("2:i_krf_total = 0x%X ; convert = 0x%X",i_krf_total[1][5:1], krf_total_cvrt[2]);
            $display("3:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[1][0:0], i_krf_total[2][7:4]}, krf_total_cvrt[3]);
            $display("4:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[2][3:0], i_krf_total[3][7:7]}, krf_total_cvrt[4]);
        end
        
        return krf_total_cvrt;
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




    //========================================
    // Test Cases
    //========================================


    /*
     tb_testname : description
     */
    task automatic test1;

        begin
            //TODO
        end

    endtask : test1


endmodule