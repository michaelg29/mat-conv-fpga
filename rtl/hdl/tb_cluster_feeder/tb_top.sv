`timescale 1ns/1ps

`include "uvm_macros.svh"


module tb_top
    #(
        parameter FIFO_WIDTH = 8,
        parameter KERNEL_SIZE = 5,
        parameter MAX_PIXEL_VAL = 10,
        parameter int TESTS_TO_RUN[3] = '{1,2}, // IDs of tasks to run
        parameter int NUM_REPS = 5, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0 //Seed for the random input generation
    );

    import uvm_pkg::*;

    // Signals
    reg i_clk;
    reg [FIFO_WIDTH-1:0][7:0] i_pixels;
    reg i_new;
    reg i_sel;
    reg [KERNEL_SIZE-1:0][7:0] o_pixels;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    // Clock
    const int clk_period = 200; //ns (5MHz)

    initial begin
        i_clk = 0;
    end

    always #(clk_period / 2) begin
        i_clk <= ~i_clk;
    end


    // DUT (cluster feeder)
    cluster_feeder DUT(
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



    //========================================
    // Testbench
    //========================================
    initial begin

        foreach (TESTS_TO_RUN[i]) begin

            // Reset all signals to 0
            i_pixels = 'h0;
            i_sel = 1'h0;
            i_new = 1'h0;

            // Reset IP for test
            //reset(.clk(i_clk), .en(), .rst());

            $display("Running test %0d", TESTS_TO_RUN[i]);
            case (TESTS_TO_RUN[i])
                1 : begin      
                    test1(.i_clk(i_clk),
                        .i_pixels(i_pixels),
                        .i_new(i_new),
                        .i_sel(i_sel),
                        .o_pixels(o_pixels));
                    end
                2 : begin
                    test2(.i_clk(i_clk),
                        .i_pixels(i_pixels),
                        .i_new(i_new),
                        .i_sel(i_sel),
                        .o_pixels(o_pixels));
                    end
                default : $display("WARNING: %0d is not a valid task ID", TESTS_TO_RUN[i]);
            endcase
        end

        $finish(0);
        
    end




    //========================================
    // Tasks
    //========================================


    task reset;
        input reg clk;    
        output en;
        output rst;
        begin
            @(posedge clk);
            en = 1'b0;
            rst = 1'b1;
            @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
            en = 1'b1;
            @(posedge clk);
        end
    endtask : reset


    //========================================
    // Test Cases
    //========================================


    // tb_cluster_feeder_parallel_load : load 8 pixels in parallel, then shift until all the 8 input pixels have been seen. Repeat NUM_REPS times.
    task automatic test1;
        ref reg i_clk;
        ref [KERNEL_SIZE-1:0][7:0] o_pixels;
        ref reg [FIFO_WIDTH-1:0][7:0] i_pixels;
        ref reg i_new;
        ref reg i_sel;

        begin
            for (int j = 0 ; j < NUM_REPS ; j++) begin

                @(negedge i_clk);
                i_pixels = 64'hBEEF50B3CAFE6688;
                //assert(std::randomize(i_pixels)); //NEED LICENSE
                i_sel = 1'b1; // parallel load
                i_new = 1'b1; // pipeline shall load
                @(posedge i_clk);
                @(negedge i_clk);
                i_sel = 1'b0; // switch to serial load
                i_new = 1'b0; // pipeline shall shift

                for (int i = 0 ; i < (FIFO_WIDTH-KERNEL_SIZE+1) ; i++) begin
                    //$display("o_pixels = 0x%X ; expected = 0x%X for i: %i", o_pixels, i_pixels[i+:5], i);

                    if(i != 0) begin
                        //Shift pixels
                        @(posedge i_clk); // 1 clock cycle to output the data
                        @(negedge i_clk); // let data appear at output
                    end

                    // check pixels
                    // variable part select
                    if(i_pixels[i+:5] != o_pixels) begin
                        `uvm_error("tb_top", $sformatf("Test 1 failed at i = %d\r\no_pixels = 0x%X ; expected = 0x%X",i,o_pixels, i_pixels[i+:5]))
                        @(negedge i_clk); // let data appear at output
                        $finish(2);
                    end
                end
                
            end

            $display("Test 1 passed");
        end

    endtask : test1


    // tb_cluster_feeder_serial_load : load 8 pixels in parallel, then shift until all the 8 input pixels have been seen. Switch to serial load
    // and load 8 pixels serially. Repeat the serial load NUM_REPS times
    task automatic test2;
        ref reg i_clk;
        ref [KERNEL_SIZE-1:0][7:0] o_pixels;
        ref reg [FIFO_WIDTH-1:0][7:0] i_pixels;
        ref reg i_new;
        ref reg i_sel;

        begin

            /*
             * Parallel load
             */
            @(negedge i_clk);
            i_pixels = 64'hBEEF50B3CAFE6688;
            //assert(std::randomize(i_pixels)); //NEED LICENSE
            i_sel = 1'b1; // parallel load
            i_new = 1'b1; // pipeline shall load
            @(posedge i_clk);
            @(negedge i_clk);
            i_sel = 1'b0; // switch to serial load
            i_new = 1'b0; // pipeline shall shift

            for (int i = 0 ; i < (FIFO_WIDTH-KERNEL_SIZE+1) ; i++) begin
                //$display("o_pixels = 0x%X ; expected = 0x%X for i: %i", o_pixels, i_pixels[i+:5], i);

                if(i != 0) begin
                    //Shift pixels
                    @(posedge i_clk); // 1 clock cycle to output the data
                    @(negedge i_clk); // let data appear at output
                end

                // check pixels
                // variable part select
                if(i_pixels[i+:5] != o_pixels) begin
                    `uvm_error("tb_top", $sformatf("Test 1 failed at i = %d\r\no_pixels = 0x%X ; expected = 0x%X",i,o_pixels, i_pixels[i+:5]))
                    @(negedge i_clk); // let data appear at output
                    $finish(2);
                end
            end
            

            /*
             * Serial load
             */
             for (int j = 0 ; j < NUM_REPS ; j++) begin

                i_pixels = 64'hBEEF50B3CAFE6688;
                //assert(std::randomize(i_pixels)); //NEED LICENSE
                i_sel = 1'b0; // switch to serial load
                i_new = 1'b1; // pipeline shall load (note that the current output pixel of the pipeline shall still be shifted while the new pixels are loaded)
                @(posedge i_clk);
                @(negedge i_clk);
                i_new = 1'b0; // pipeline shall shift

                for (int i = 0 ; i < (FIFO_WIDTH-KERNEL_SIZE+1) ; i++) begin
                    $display("o_pixels = 0x%X ; expected = 0x%X for i: %i", o_pixels, i_pixels[i+:5], i);

                    if(i != 0) begin
                        //Shift pixels
                        @(posedge i_clk); // 1 clock cycle to output the data
                        @(negedge i_clk); // let data appear at output
                    end

                    // check pixels
                    // variable part select
                    if(i_pixels[i+:5] != o_pixels) begin
                        `uvm_error("tb_top", $sformatf("Test 1 failed at i = %d\r\no_pixels = 0x%X ; expected = 0x%X",i,o_pixels, i_pixels[i+:5]))
                        @(negedge i_clk); // let data appear at output
                        $finish(2);
                    end
                end

            end

            $display("Task 2 passed");
        end

    endtask : test2


endmodule