`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 2, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_core_io_pipeline", // Name of test case to run

        parameter MIN_PIXEL_VAL = 40'h160,
        parameter MAX_PIXEL_VAL = 40'h210,
        parameter MIN_KERNEL_VAL = 40'h160,
        parameter MAX_KERNEL_VAL = 40'h210,
        parameter MIN_SUB_VAL = 18'h0,
        parameter MAX_SUB_VAL = 18'h10,
        parameter ROUNDING = 3'b100
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    reg i_clk;
    reg i_en;
    logic [KERNEL_SIZE-1:0][7:0] i_pixels;
    logic [KERNEL_SIZE-1:0][7:0] i_kernels;
    logic [17:0] i_sub;
    logic [17:0] o_res;

    // Variables declarations (packed arrays)
    var longint i1 = 0; // 5 pixels
    var longint j1 = 0; // 5 kernel values
    var longint k1 = 0; // sub
    var longint i2 = 0; // 5 pixels
    var longint j2 = 0; // 5 kernel values
    var longint k2 = 0; // sub
    var longint oreg = 0;

    // use time to get 64-bit signed int (only need 40-bits for i and j)
    var longint i;
    var longint j;
    var longint k;

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

    core #(
        .i_round({41'b0,ROUNDING})
    )
    DUT(
        .i_clk      (i_clk),
        .i_en       (i_en),
        .i_s0       (i_pixels[0]),
        .i_s1       (i_pixels[1]),
        .i_s2       (i_pixels[2]),
        .i_s3       (i_pixels[3]),
        .i_s4       (i_pixels[4]),
        .i_k0       (i_kernels[0]),
        .i_k1       (i_kernels[1]),
        .i_k2       (i_kernels[2]),
        .i_k3       (i_kernels[3]),
        .i_k4       (i_kernels[4]),
        .i_sub      (i_sub),
        .o_res      (o_res)
    );

    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_core_io_no_pipeline",
        "tb_core_io_pipeline"
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
                    reset_dut(i_clk);

                    case (i+1)
                        1 : begin      
                            test1(
                                .i_clk(i_clk),
                                .i_en(i_en),
                                .i_pixels(i_pixels),
                                .i_kernels(i_kernels),
                                .i_sub(i_sub),
                                .o_res(o_res)
                                );
                            end
                        2 : begin
                            test2(
                                .i_clk(i_clk),
                                .i_en(i_en),
                                .i_pixels(i_pixels),
                                .i_kernels(i_kernels),
                                .i_sub(i_sub),
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
        ref reg clk;    
        begin
            // Reset all signals to 0
            i_en = 0;
            i_pixels = 0;
            i_kernels = 0;
            i_sub = 0;
            @(negedge clk);
        end
    endtask : reset_dut



    //========================================
    // Test Cases
    //========================================


    /*
     tb_core_io_no_pipeline : non-pipelined test of input to output
     */
    task automatic test1;
        ref reg i_clk;
        ref reg i_en;
        ref logic [KERNEL_SIZE-1:0][7:0] i_pixels;
        ref logic [KERNEL_SIZE-1:0][7:0] i_kernels;
        ref logic [17:0] i_sub;
        ref logic [17:0] o_res;

        begin
            
        // Reset all signals to 0
        i_en = 0;
        i_pixels = 0;
        i_kernels = 0;
        i_sub = 0;

        // Enable the core
        @(negedge i_clk);
        i_en = 1;

        @(negedge i_clk);
            
        // Pixel value iteration
        // (iterate through all possible pixels combinations)
        for(i = MIN_PIXEL_VAL ; i <= MAX_PIXEL_VAL ; i++) begin

            // Kernel value iteration
            // (iterate through all possible kernel values combinations)
            for(j = MIN_KERNEL_VAL ; j <= MAX_KERNEL_VAL ; j++) begin
                
                // Sub-result value iteration
                for(k = MIN_SUB_VAL ; k <= MAX_SUB_VAL ; k++) begin

                    // once a input is given, it takes 2 clock cycles
                    // before output. 


                    // For each new values:
                    // First clock cycle : assign new values
                    // Second clock cycle : wait for computation
                    // Third clock cycle: check output values
                    @(negedge i_clk);
                    
                    // New values
                    i_pixels = i;  
                    i_kernels = j; 
                    i_sub = k;

                    // Wait for output result
                    @(posedge i_clk);

                    @(negedge i_clk);
                    // Reset values
                    i_pixels = 0;  
                    i_kernels = 0; 
                    i_sub = 0;

                    @(negedge i_clk); //computation wait
                    @(negedge i_clk); //o_res has correct value (output ready)

                    // Calculate value that should be obtained
                    oreg = k;
                    oreg += ROUNDING;
                    for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                        // Use variable part-select with fixed width
                        oreg += signed'(i[8*s +: 8]) * signed'(j[8*s +: 8]);
                    end

                    // Compare output to valid result
                    if(oreg[20:3] != o_res) begin
                        `uvm_error("tb_top", $sformatf("Test failed at i = %d ; j = %d ; k = %d\no_res = 0x%X ; expected = 0x%X",i,j,k,o_res,oreg[20:3]));
                        @(negedge i_clk);
                        $finish(2);
                    end

                end

            end

        end

        `uvm_info("tb_top", "Test tb_core_io_no_pipeline passed", UVM_NONE);
        end

    endtask : test1




    /*
     tb_core_io_pipeline : pipelined test of input to output
     */
    task automatic test2;
        ref reg i_clk;
        ref reg i_en;
        ref logic [KERNEL_SIZE-1:0][7:0] i_pixels;
        ref logic [KERNEL_SIZE-1:0][7:0] i_kernels;
        ref logic [17:0] i_sub;
        ref logic [17:0] o_res;

        int count = 0; //Clock cycle counter for flag
        int data_ready; //Flag to indicate can check the output

        begin
            
        // Reset all signals to 0
        i_en = 0;
        i_pixels = 0;
        i_kernels = 0;
        i_sub = 0;
        data_ready = 0;
        count = 0;
       
        i1 = 0;
        j1 = 0;
        k1 = 0;
        i2 = 0;
        j2 = 0;
        k2 = 0;

        // Enable the core
        @(negedge i_clk);
        i_en = 1;

        @(negedge i_clk);
            
        // Pixel value iteration
        // (iterate through all possible pixels combinations)
        for(i = MIN_PIXEL_VAL ; i <= MAX_PIXEL_VAL ; i++) begin

            // Kernel value iteration
            // (iterate through all possible kernel values combinations)
            for(j = MIN_KERNEL_VAL ; j <= MAX_KERNEL_VAL ; j++) begin
                
                // Sub-result value iteration
                for(k = MIN_SUB_VAL ; k <= MAX_SUB_VAL ; k++) begin

                    // once a input is given, it takes 2 clock cycles
                    // before output. 

                    // For each new values:
                    // First clock cycle : assign new values (pipeline)
                    // Second clock cycle : wait for computation
                    // Third clock cycle: check output values
                    
                    // Load new values (first clk cycle)
                    i_pixels = i;  
                    i_kernels = j; 
                    i_sub = k;

                    @(negedge i_clk); // Load input/Get output result
                    count++;
                    if(count > 2) data_ready = 1;

                    // Calculate value that should be obtained (thid clock cycle check)
                    oreg = k1;
                    oreg += ROUNDING;
                    for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                        // Use variable part-select with fixed width
                        oreg += signed'(i1[8*s +: 8]) * signed'(j1[8*s +: 8]);
                    end

                    // if not first or second clock cycles
                    if(data_ready == 1) begin
                        // Compare output to valid result
                        if(oreg[20:3] != o_res) begin
                            `uvm_error("tb_top", $sformatf("Test failed at i = %d ; j = %d ; k = %d\no_res = 0x%X ; expected = 0x%X",i,j,k,o_res,oreg[20:3]));
                            @(negedge i_clk);
                            $finish(2);
                        end
                    end

                    // Get input from previous (ready for third clock cycle)
                    i1 = i2;
                    j1 = j2;
                    k1 = k2;

                    // Save current input for next check (ready for second clock cycle)
                    i2 = i;
                    j2 = j;
                    k2 = k;

                end
            end

        end

        `uvm_info("tb_top", "Test tb_core_io_pipeline passed", UVM_NONE);
        end

    endtask : test2



endmodule