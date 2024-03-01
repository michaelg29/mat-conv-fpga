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
    logic i_is_subj;
    logic i_new_pkt;
    logic i_discont;
    logic [FIFO_WIDTH-1+KERNEL_SIZE-1:0][7:0] i_pkt; //input pixels from FIFO + buffered pixels
    logic [17:0] o_pixel;

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
        .i_is_subj(i_is_subj),
        .i_new_pkt(i_new_pkt),
        .i_discont(i_discont),
        .i_pkt(i_pkt),
        .o_pixel(o_pixel)
    );


    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_testcase name",
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


    /*
        Calculate a matrix convolution for a subject the size of the kernel
        using the operations in the cluster (rounding)
        @param[in] kern: kernel 2D array
        @param[in] subj: subject 2D array
    */
    function logic [17:0] local_convolution;

        input logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] kernel;

        logic [17:0]result = ROUNDING;

        for(int i = 0 ; i < KERNEL_SIZE ; i++) begin
            for(int j = 0 ; j < KERNEL_SIZE ; j++) begin
                result = ROUNDING

            end
            //Perform rounding for row dot product
        end

        //Perform clamping

        return result;
    endfunction

    //========================================
    // Tasks
    //========================================

    /*
        Reset DUT
    */
    task automatic reset_dut;
        ref reg clk;    
        begin
            //TODO
        end
    endtask : reset_dut



    //========================================
    // Test Cases
    //========================================


    /*
     tb_testname : description
     */
    task automatic test1;
        ref reg i_clk;
        ref logic i_newrow;
        ref logic i_is_kern;
        ref logic i_is_subj;
        ref logic i_new_pkt;
        ref logic i_discont;
        ref logic [FIFO_WIDTH-1+KERNEL_SIZE-1:0][7:0] i_pkt; //input pixels from FIFO + buffered pixels
        ref logic [17:0] o_pixel;

        begin
            //TODO
        end

    endtask : test1


endmodule