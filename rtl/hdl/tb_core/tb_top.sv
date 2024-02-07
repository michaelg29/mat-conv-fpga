`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter MIN_PIXEL_VAL = 40'h160,
        parameter MAX_PIXEL_VAL = 40'h210,
        parameter MIN_KERNEL_VAL = 40'h160,
        parameter MAX_KERNEL_VAL = 40'h210,
        parameter MIN_SUB_VAL = 18'h0,
        parameter MAX_SUB_VAL = 18'h10,
        parameter PIPELINE = 1,
        parameter ROUNDING = 3'b100
    );

    import uvm_pkg::*;

    // Signals
    reg i_clk;
    reg i_en;
    logic [KERNEL_SIZE-1:0][7:0] i_pixels;
    logic [KERNEL_SIZE-1:0][7:0] i_kernels;
    logic [17:0] i_sub;
    wire [17:0] o_res;

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

    // Clock
    const int clk_period = 200; //ns (5MHz)

    initial begin
        i_clk = 0;
    end

    always #(clk_period / 2) begin
        i_clk <= ~i_clk;
    end

    // DUT (core)
    core DUT(
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

    // Testbench
    /*
    1-Wait negative edge
    2-Assign new value
    3-Check previous values result
    */
    initial begin

        $display("Core Testbench Starts");
        if(PIPELINE == 1) begin
            $display("Pipelined testbench");
        end else begin
            $display("Non-pipelined testbench");
        end

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


                    if(PIPELINE == 1) begin

                        // For each new values:
                        // First clock cycle : assign new values (pipeline)
                        // Second clock cycle : wait for computation
                        // Third clock cycle: check output values
                        
                        // New values (first clk cycle)
                        i_pixels = i;  
                        i_kernels = j; 
                        i_sub = k;

                        // Load input/Get output result
                        @(posedge i_clk); 

                        @(negedge i_clk); //o_res has correct value

                        // Calculate value that should be obtained (thid clock cycle check)
                        oreg = k1;
                        oreg += ROUNDING;
                        for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                            // Use variable part-select with fixed width
                            oreg += signed'(i1[8*s +: 8]) * signed'(j1[8*s +: 8]);
                        end

                        // if not first or second input
                        if((i != 0) || (j != 0) || ((k != 0) && (k != 1))) begin
                            // Compare output to valid result
                            if(oreg[20:3] != o_res) begin
                                @(negedge i_clk);
                                $display("Test failed for i: %d ; j: %d ; k: %d",i,j,k);
                                $display("oreg[20:3]: %d ; oreg: %d ; o_res: %d",oreg[20:3], oreg, o_res);
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
                    end else begin
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

                        @(posedge i_clk); //computation wait
                        @(posedge i_clk); //output ready

                        @(negedge i_clk); //o_res has correct value

                        // Calculate value that should be obtained
                        oreg = k;
                        oreg += ROUNDING;
                        for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                            // Use variable part-select with fixed width
                            oreg += signed'(i[8*s +: 8]) * signed'(j[8*s +: 8]);
                        end

                        // Compare output to valid result
                        if(oreg[20:3] != o_res) begin
                            @(negedge i_clk);
                            $display("Test failed for i: %d ; j: %d ; k: %d",i,j,k);
                            $display("oreg[20:3]: %d ; oreg: %d ; o_res: %d",oreg[20:3], oreg, o_res);
                            $finish(2);
                        end

                    end

                end
            end

        end

        $display("Test passed");
        $finish(0);
    end


endmodule