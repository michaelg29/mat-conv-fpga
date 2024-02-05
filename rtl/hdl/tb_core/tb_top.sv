`timescale 1ns/100ps


module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter MAX_PIXEL_VAL = 10,
        parameter MAX_KERNEL_VAL = 10,
        parameter MAX_SUB_VAL = 10
    );

    // Signals
    reg clk;
    logic [KERNEL_SIZE-1:0][7:0] i_pixels;
    logic [KERNEL_SIZE-1:0][7:0] i_kernels;
    logic [7:0] i_sub;
    wire [17:0] o_res;
    wire o_valid; //TO REMOVE

    // Variables declarations (packed arrays)
    var reg [4:0][7:0] ireg = 0; // 5 pixels
    var reg [4:0][7:0] jreg = 0; // 5 kernel values
    var reg [39:0] kreg = 0; // sub
    var reg [17:0] oreg = 0;

    // use time to get 64-bit unsigned int
    var time i;
    var time j;
    var time k;

    // Clock
    const int clk_freq = 5; //MHz

    initial begin
        clk = 0;
    end

    always #(1/clk_freq) clk = ~clk;

    // DUT (core)
    core dut(
        .i_clk    (clk),
        .i_s0   (i_pixels[0]),
        .i_s1   (i_pixels[1]),
        .i_s2   (i_pixels[2]),
        .i_s3   (i_pixels[3]),
        .i_s4   (i_pixels[4]),
        .i_k0   (i_kernels[0]),
        .i_k1   (i_kernels[1]),
        .i_k2   (i_kernels[2]),
        .i_k3   (i_kernels[3]),
        .i_k4   (i_kernels[4]),
        .i_sub  (i_sub),
        .o_res  (o_res),
        .o_valid (o_valid) //REMOVE IN CORE DESIGN
    );

    // Testbench
    initial begin

        // Reset all signals to 0
        //https://stackoverflow.com/questions/58172209/how-to-use-parameterized-bitwidth-for-a-constant-value-in-verilog
        i_pixels = '{(KERNEL_SIZE*8)'('h0)};
        i_kernels = '{'h0};
        i_sub = '{8'h0};
            
        // Pixel value iteration
        // (iterate through all possible pixels combinations)
        for(i = 0 ; i < MAX_PIXEL_VAL ; i++) begin

            // Kernel value iteration
            // (iterate through all possible kernel values combinations)
            for(j = 0 ; j < MAX_KERNEL_VAL ; j++) begin
                
                // Sub-result value iteration
                for(k = 0 ; k < MAX_SUB_VAL ; k++) begin

                    // once a input is given, it takes 2 clock cycles
                    // before output. 

                    // For each new values:
                    // First clock cycle : assign new values (pipeline)
                    // Second clock cycle: check output values
                    @(posedge clk);
                    
                    // New values
                    i_pixels = i;  
                    i_kernels = j; 
                    i_sub = k;

                    // if first input, do nothing
                    if((i == 0) && (j == 0) && (k == 0)) begin
                        continue;
                    end

                    // Calculate value that should be obtained
                    oreg += kreg;
                    for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                        oreg += ireg[s] * kreg[s];
                    end

                    // Compare output to valid result
                    if(oreg != o_res) begin
                        $display("Test failed for i: %d ; j: %d ; k: %d",i,j,k);
                        $finish(2);
                    end

                    // Save current input for next check
                    ireg = i;
                    jreg = j;
                    kreg = k;

                end
            end

        end

        $display("Test passed");
    end


endmodule