`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter MAX_PIXEL_VAL = 40'hFF,
        parameter MAX_KERNEL_VAL = 40'hFF,
        parameter MAX_SUB_VAL = 18'h8,
        parameter PIPELINE = 0,
        parameter ROUNDING = 3'b100
    );

    import uvm_pkg::*;

    // Signals
    reg i_clk;
    reg i_en;
    reg i_rst_n;
    logic [KERNEL_SIZE-1:0][7:0] i_pixels;
    logic [KERNEL_SIZE-1:0][7:0] i_kernels;
    logic [17:0] i_sub;
    wire [17:0] o_res;
    wire o_valid; //TO REMOVE

    // Variables declarations (packed arrays)
    var reg [4:0][7:0] ireg1 = 0; // 5 pixels
    var reg [4:0][7:0] jreg1 = 0; // 5 kernel values
    var reg [17:0] kreg1 = 0; // sub
    var reg [4:0][7:0] ireg2 = 0; // 5 pixels
    var reg [4:0][7:0] jreg2 = 0; // 5 kernel values
    var reg [17:0] kreg2 = 0; // sub
    var longint oreg = 0;

    // use time to get 64-bit unsigned int
    var time i;
    var time j;
    var time k;

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
        .i_rst_n    (i_rst_n),
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
        .o_res      (o_res),
        .o_valid    (o_valid) //REMOVE IN CORE DESIGN
    );

    // Testbench
    /*
    1-Wait negative edge
    2-Assign new value
    3-Check previous values result
    */
    initial begin

        $display("Core Testbench Starts");

        // Reset all signals to 0
        i_en = 0;
        i_rst_n = 0;
        i_pixels = 0;
        i_kernels = 0;
        i_sub = 0;

        // Enable the core
        @(posedge i_clk); 
        i_en = 1;

        //Put core out of reset
        @(posedge i_clk);
        i_rst_n = 1;

        @(posedge i_clk);
            
        // Pixel value iteration
        // (iterate through all possible pixels combinations)
        for(i = 0 ; i <= MAX_PIXEL_VAL ; i++) begin

            // Kernel value iteration
            // (iterate through all possible kernel values combinations)
            for(j = 0 ; j <= MAX_KERNEL_VAL ; j++) begin
                
                // Sub-result value iteration
                for(k = 0 ; k <= MAX_SUB_VAL ; k++) begin

                    // once a input is given, it takes 2 clock cycles
                    // before output. 


                    if(PIPELINE == 1) begin

                        //TODO FIX MATH BLOCK FIRST

                        // For each new values:
                        // First clock cycle : assign new values (pipeline)
                        // Second clock cycle: check output values
                        @(negedge i_clk);
                        
                        // New values
                        i_pixels = i;  
                        i_kernels = j; 
                        i_sub = k;


                        // Calculate value that should be obtained
                        oreg = kreg1;
                        oreg += ROUNDING;
                        for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                            oreg += ireg1[s] * kreg1[s];
                        end

                        // Wait for output result
                        @(posedge i_clk);

                        $display("oreg: %d ; o_res: %d",oreg[20:3], o_res);

                        // if not first or second input
                        if((i != 0) || (j != 0) || ((k != 0) || (k != 1))) begin
                            // Compare output to valid result
                            if(oreg[20:3] != o_res) begin
                                $display("Test failed for i: %d ; j: %d ; k: %d",i,j,k);
                                $finish(2);
                            end
                        end

                        // Get input from previous
                        ireg1 = ireg2;
                        jreg1 = jreg2;
                        kreg1 = kreg2;

                        // Save current input for next check
                        ireg2 = i;
                        jreg2 = j;
                        kreg2 = k;
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
                        @(posedge i_clk); //input in
                        @(posedge i_clk); //wait
                        @(posedge i_clk); //wait
                        @(posedge i_clk); //output ready

                        @(negedge i_clk);

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
                            $display("oreg[]: %d ; oreg: %d ; o_res: %d",oreg[20:3], oreg, o_res);
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