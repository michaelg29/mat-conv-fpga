`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter MIN_KERNEL_VAL = 40'h160,
        parameter MAX_KERNEL_VAL = 40'h210,
        parameter PIPELINE = 1,
        parameter int TESTS_TO_RUN[3] = '{1} // IDs of tasks to run
    );

    import uvm_pkg::*;

    //========================================
    // Signals
    //========================================
    reg i_clk;
    reg i_valid;
    reg i_rst;

    logic [FIFO_WIDTH-1:0][7:0] i_kernels;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]


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
    krf DUT(
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


    //========================================
    // Testbench
    //========================================
    initial begin

        foreach (TESTS_TO_RUN[i]) begin

            // Reset all data to 0
            i_kernels = 'h0;

            // Reset the DUT for new test
            reset(.clk(i_clk), .rst(i_rst));
            
            $display("Running test %0d", TESTS_TO_RUN[i]);
            case (TESTS_TO_RUN[i])
                1 : begin      
                    test1(.i_clk(i_clk),
                          .i_valid(i_valid),
                          .i_rst(i_rst),
                          .i_kernels(i_kernels),
                          .o_kernels(o_kernels));
                    end
                2 : begin
                    test2();
                    end
                default : $display("WARNING: %0d is not a valid task ID", TESTS_TO_RUN[i]);
            endcase
        end

        `uvm_info("tb_top", "All tests passed", UVM_NONE);
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
        //$display("0:i_krf_total = 0x%X ; convert = 0x%X",i_krf_total[0][7:3], krf_total_cvrt[0]);

        krf_total_cvrt[1] = {i_krf_total[0][2:0], i_krf_total[1][7:6]};
        //$display("1:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[0][2:0], i_krf_total[1][7:6]}, krf_total_cvrt[1]);

        krf_total_cvrt[2] = i_krf_total[1][5:1];
        //$display("2:i_krf_total = 0x%X ; convert = 0x%X",i_krf_total[1][5:1], krf_total_cvrt[2]);


        krf_total_cvrt[3] = {i_krf_total[1][0:0], i_krf_total[2][7:4]};
        //$display("3:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[1][0:0], i_krf_total[2][7:4]}, krf_total_cvrt[3]);


        krf_total_cvrt[4] = {i_krf_total[2][3:0], i_krf_total[3][7:7]};
        //$display("4:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[2][3:0], i_krf_total[3][7:7]}, krf_total_cvrt[4]);
        return krf_total_cvrt;
    endfunction



    //========================================
    // Tasks
    //========================================

    task automatic reset;
        ref reg clk;    
        ref rst;
        begin
            @(negedge clk);
            rst = 1'b1;
            @(negedge clk);
            rst = 1'b0;
            @(negedge clk);
        end
    endtask : reset



    //========================================
    // Test Cases
    //========================================


    // Test 1 : i_rst asserted, i_valid asserted next clock cycle
    task automatic test1;
        ref reg i_clk;
        ref reg i_valid;
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output

        begin
            @(negedge i_clk);
            i_rst = 1'b1; //reset state machine -> ready to program
            @(negedge i_clk);

            for (int i = 0 ; i < 4 ; i++) begin

                // Load a row
                i_kernels = 64'hBEEF50B3CAFE66C2; //first BEEF is top-left two bytes, last B3 is third value of second row
                i_krf_total[i] = i_kernels;
                krf_total_cvrt = krf_convert(i_krf_total);

                i_valid = 1'b1;
                @(negedge i_clk);
                i_valid = 1'b0; // check output and make no new row is loaded

                @(posedge i_clk); // 1 clock cycle to output the data
                @(negedge i_clk); // let data appear at output

                // check pixels
                // variable part select
                if(krf_total_cvrt != o_kernels) begin
                    `uvm_error("tb_top", $sformatf("Test 1 failed at i = %d",i));
                    $display("o_kernels = 0x%X ; expected = 0x%X",o_kernels, krf_total_cvrt);
                    $display("i_k: 0x%X ; i_t: 0x%X",i_kernels, i_krf_total);
                    @(negedge i_clk); // let data appear at output
                    $finish(2);
                end
            end
                
            `uvm_info("tb_top", "Test 1 passed", UVM_NONE);
        end

    endtask : test1


    // Test 2 : i_rst asserted and i_valid asserted at the same time
    task test2;

        begin
            $display("Task 2");
        end
    endtask : test2

endmodule