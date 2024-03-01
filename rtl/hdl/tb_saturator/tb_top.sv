`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 1, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_saturator_io_unsigned", // Name of test case to run

        parameter MIN_VAL = 18'h0,
        parameter MAX_VAL = 18'h10
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    reg i_clk;
    reg i_sign;
    logic [17:0] i_val;
    logic [7:0] o_res; 

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
    saturator DUT(
        .i_clk(i_clk),
        .i_sign(i_sign),
        .i_val(i_val),
        .o_res(o_res)
    );


    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_saturator_io_unsigned",
        "tb_saturator_io_signed"
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
                    //reset_dut(i_clk);

                    case (i+1)
                        1 : begin      
                            test1(
                                .i_clk(i_clk),
                                .i_sign(i_sign),
                                .i_val(i_val),
                                .o_res(o_res)
                            );
                            end
                        2 : begin
                            test2(
                                .i_clk(i_clk),
                                .i_sign(i_sign),
                                .i_val(i_val),
                                .o_res(o_res)
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

    //TODO: add helper functions if necessary

    //========================================
    // Tasks
    //========================================

    /*
        Reset DUT
    */
    task automatic reset_dut;
        ref reg i_clk;    
        begin
            //None
        end
    endtask : reset_dut



    //========================================
    // Test Cases
    //========================================


    /*
     tb_saturator_io_unsigned : checks saturator behavior for unsigned I/O (i_sign=0)
     */
    task automatic test1;
        ref reg i_clk;
        ref reg i_sign;
        ref logic [17:0] i_val;
        ref logic [7:0] o_res; 

        logic [7:0] ovalid;

        begin

            // Reset all signals to 0
            i_sign = 0;
            i_val = 0;
            @(negedge i_clk);

            // Set the core to unsigned
            i_sign = 0;
            @(negedge i_clk);

            // iterate through all possible inputs
            for(int i = MIN_VAL ; i <= MAX_VAL ; i++) begin

                // New value
                i_val = i;
                @(negedge i_clk); //load input
                @(negedge i_clk); //data appears at output 

                // Calculate valid result
                if (i_val <= UNSIGNED_UPPER_BOUND) begin
                    ovalid = i_val[11:4];
                end else begin
                    ovalid = UNSIGNED_UPPER_BOUND[11:4];
                end

                if(VERBOSE) begin
                    $display("in: 0x%X", i_val);
                    $display("ovalid: 0x%X", ovalid);
                end

                // Compare output to valid result
                if(ovalid != o_res) begin
                    `uvm_error("tb_top", $sformatf("Test failed at i_val=0x%X\no_res = 0x%X ; expected = 0x%X",i_val,o_res,ovalid));
                    @(negedge i_clk);
                    $finish(2);
                end

            end

            `uvm_info("tb_top", "Test tb_saturator_io_unsigned passed", UVM_NONE);
        end

    endtask : test1


     /*
     tb_saturator_io_signed : checks saturator behavior for signed I/O (i_sign=1)
     */
    task automatic test2;
        ref reg i_clk;
        ref reg i_sign;
        ref logic [17:0] i_val;
        ref logic [7:0] o_res; 

        logic [7:0] ovalid;

        begin
            
            // Reset all signals to 0
            i_sign = 0;
            i_val = 0;
            @(negedge i_clk);

            // Set the core to signed
            i_sign = 1;
            @(negedge i_clk);

            // iterate through all possible inputs
            for(int i = MIN_VAL ; i <= MAX_VAL ; i++) begin

                // New value
                i_val = i;
                @(negedge i_clk); //load input
                @(negedge i_clk); //data appears at output 

                // Calculate valid result
                if(signed'(i_val) < 0) begin //negative input
                    if (signed'(i_val) >= signed'(SIGNED_LOWER_BOUND)) begin //if between SIGNED_LOWER_BOUND and 0
                        ovalid = i_val[11:4];
                    end else begin //if below SIGNED_LOWER_BOUND
                        ovalid = SIGNED_LOWER_BOUND[11:4];
                    end
                end else begin //positive input
                    if (signed'(i_val) <= signed'(SIGNED_UPPER_BOUND)) begin //if between 0 and SIGNED_UPPER_BOUND
                        ovalid = i_val[11:4];
                    end else begin //if above SIGNED_UPPER_BOUND
                        ovalid = SIGNED_UPPER_BOUND[11:4];
                    end
                end

                // Compare output to valid result
                if(ovalid != o_res) begin
                    `uvm_error("tb_top", $sformatf("Test failed at i_val=0x%X\no_res = 0x%X ; expected = 0x%X",i_val,o_res,ovalid));
                    @(negedge i_clk);
                    $finish(2);
                end

            end

            `uvm_info("tb_top", "Test tb_saturator_io_signed passed", UVM_NONE);
        end

    endtask : test2


endmodule