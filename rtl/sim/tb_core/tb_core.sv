`timescale 1ns/0.1ns


module tb_core
    #(
        parameter KERNEL_SIZE = 5,
        parameter MAX_PIXEL_VAL = 10,
        parameter MAX_KERNEL_VAL = 10,
        parameter MAX_SUB_VAL = 10
    );

    // Signals
    reg clk;
    reg i_pixel[KERNEL_SIZE*8-1:0];
    reg i_kernel[KERNEL_SIZE*8-1:0];
    reg i_sub[7:0];
    wire o_res[17:0];

    // Clock
    const int clk_freq = 5; //MHz

    initial begin
        clk = 0;
    end

    always #(1/clk_freq) clk = ~clk;


    // DUT (core)
    core dut(
        .clk    (clk),
        .i_s0   (i_pixel[7:0]),
        .i_s1   (i_pixel[15:8]),
        .i_s2   (i_pixel[23:16]),
        .i_s3   (i_pixel[31:24]),
        .i_s4   (i_pixel[39:32]),
        .i_k0   (i_kernel[7:0]),
        .i_k1   (i_kernel[15:8]),
        .i_k2   (i_kernel[23:16]),
        .i_k3   (i_kernel[31:24]),
        .i_k4   (i_kernel[39:32]),
        .i_sub  (i_sub),
        .o_res  (o_res)
    );



    // Testbench
    initial begin
        // Reset all signals to 0
        i_pixel = (KERNEL_SIZE*8-1):0'h0;
        i_kernel = (KERNEL_SIZE*8-1):0'h0;
        i_sub = 8'h0;

        reg ireg[39:0];
        reg jreg[39:0];
        reg kreg[39:0];
        reg oreg[17:0];

            
        // Pixel value iteration
        for(unsigned longint i = 0 ; i < MAX_PIXEL_VAL ; i++) begin

            // Kernel value iteration
            for(unsigned longint j = 0 ; i < MAX_KERNEL_VAL ; i++) begin
                
                // Sub-result value iteration
                for(unsigned longint k = 0 ; i < MAX_SUB_VAL ; i++) begin

                    // Wait for falling edge 
                    @(posedge clk);
                    i_pixel = i;
                    i_kernel = j;
                    i_sub = k;

                    ireg = i;
                    jreg = j;
                    kreg = k;

                    // Get result
                    oreg = o_res;

                    // Calculate value that should be obtained
                    for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                        // Use variable part-select with fixed width
                        oreg += ireg[8*s +: 8];
                    end

                    // Check if result is valid
                    if(oreg != o_res) begin
                        $display("Test failed for i: %d ; j: %d ; k: %d",i,j,k);
                        $finish(2);
                    end

                end
            end

        end

        $display("Test passed");
    end


endmodule