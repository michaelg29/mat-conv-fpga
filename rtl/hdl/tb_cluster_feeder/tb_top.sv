`timescale 1ns/1ps

//`include "uvm_macros.svh"


module tb_top
    #(
        parameter FIFO_WIDTH = 8,
        parameter KERNEL_SIZE = 5,
        parameter MAX_PIXEL_VAL = 10,
        parameter int TESTS_TO_RUN[3] = '{1,2,3} // IDs of tasks to run
    );

    // Signals
    reg i_clk;
    reg [FIFO_WIDTH-1:0][7:0] i_pixels;
    reg i_new;
    reg i_sel;
    reg [KERNEL_SIZE-1:0][7:0] o_pixels;

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
                    test2();
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


    // Test 1 : load 8 pixels in parallel, then shift until all the 8 input pixels have been seen
    task automatic test1;
        ref reg i_clk;
        ref [KERNEL_SIZE-1:0][7:0] o_pixels;
        ref reg [FIFO_WIDTH-1:0][7:0] i_pixels;
        ref reg i_new;
        ref reg i_sel;

        begin
            @(negedge i_clk);
            i_pixels = 64'hBEEF50B3BEEF50B3;
            i_sel = 1'b1; // parallel load
            i_new = 1'b1; // pipeline shall load
            @(posedge i_clk);
            i_sel = 1'b0; // switch to serial load
            i_new = 1'b0; // pipeline shall shift

            for (int i = 0 ; i < KERNEL_SIZE ; i++) begin
                @(posedge i_clk); // 1 clock cycle to output the data
                @(negedge i_clk); // let data appear at output
                $display("o_pixels = 0x%X ; expected = 0x%X", o_pixels, i_pixels[i+:5]);

                // check pixels
                // variable part select
                if(i_pixels[i+:5] != o_pixels) begin
                    $display("Test 1 failed at i = %d",i);
                    $display("o_pixels = 0x%X ; expected = 0x%X", o_pixels, i_pixels[i+:5]);
                    $finish(2);
                end
            end
                
            $display("Test 1 passed");
        end

    endtask : test1


    // Test 2 : 
    task test2;

        begin
            $display("Task 2");
        end
    endtask : test2


endmodule