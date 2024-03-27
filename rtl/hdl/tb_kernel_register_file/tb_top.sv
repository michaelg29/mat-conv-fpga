`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 3, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_krf_io_no_pipeline" // Name of test case to run
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    reg i_clk;
    reg i_valid;
    reg i_rst_n;

    logic [FIFO_WIDTH-1:0][7:0] i_kernels;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

    const int NUM_STATES = (KERNEL_SIZE*KERNEL_SIZE - 1)/FIFO_WIDTH + 1; //round up trick

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
        .i_rst_n      (i_rst_n),

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

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_krf_io_no_pipeline",
        "tb_krf_io_pipeline",
        "tb_krf_invalid_load",
        "tb_krf_overload"
    };

    initial begin

        //Loop through all possible test cases
        foreach (TEST_CASES[i]) begin

            //If test case, run it
            if(!uvm_re_match(TC, TEST_CASES[i])) begin

                $display("===> Running Test '%s' for %d iterations", TEST_CASES[i], NUM_REPS);
                
                for (int j = 0 ; j < NUM_REPS ; j++) begin

                    `uvm_info("tb_top", $sformatf("Iteration %d", j), UVM_NONE);

                    `uvm_info("tb_top", "Resetting DUT", UVM_NONE);
                    reset_dut(i_clk, i_rst_n, i_kernels);

                    case (i+1)
                        1 : begin      
                            test1(.i_clk(i_clk),
                                .i_valid(i_valid),
                                .i_rst_n(i_rst_n),
                                .i_kernels(i_kernels),
                                .o_kernels(o_kernels));
                            end
                        2 : begin
                            test2(.i_clk(i_clk),
                                .i_valid(i_valid),
                                .i_rst_n(i_rst_n),
                                .i_kernels(i_kernels),
                                .o_kernels(o_kernels));
                            end
                        3 : begin
                            test3(.i_clk(i_clk),
                                .i_valid(i_valid),
                                .i_rst_n(i_rst_n),
                                .i_kernels(i_kernels),
                                .o_kernels(o_kernels));
                            end
                        4 : begin
                            test4(.i_clk(i_clk),
                                .i_valid(i_valid),
                                .i_rst_n(i_rst_n),
                                .i_kernels(i_kernels),
                                .o_kernels(o_kernels));
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
        Check the current KRF output to the input values
    */
    function logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_convert;
        input [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total;

        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt;

        krf_total_cvrt[0] = i_krf_total[0][4:0];

        krf_total_cvrt[1] = {i_krf_total[1][1:0], i_krf_total[0][7:5]};

        krf_total_cvrt[2] = i_krf_total[1][6:2];

        krf_total_cvrt[3] = {i_krf_total[2][3:0], i_krf_total[1][7:7]};

        krf_total_cvrt[4] = {i_krf_total[3][0:0], i_krf_total[2][7:4]};
        
        
        if(VERBOSE) begin
            $display("0:i_krf_total = 0x%X ; convert = 0x%X",i_krf_total[0][7:3], krf_total_cvrt[0]);
            $display("1:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[0][2:0], i_krf_total[1][7:6]}, krf_total_cvrt[1]);
            $display("2:i_krf_total = 0x%X ; convert = 0x%X",i_krf_total[1][5:1], krf_total_cvrt[2]);
            $display("3:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[1][0:0], i_krf_total[2][7:4]}, krf_total_cvrt[3]);
            $display("4:i_krf_total = 0x%X ; convert = 0x%X",{i_krf_total[2][3:0], i_krf_total[3][7:7]}, krf_total_cvrt[4]);
        end
        
        return krf_total_cvrt;
    endfunction



    //========================================
    // Tasks
    //========================================

    task automatic reset_dut;
        ref reg i_clk;    
        ref reg i_rst_n;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        begin
            //Reset state machine and outputs
            i_rst_n = 1'b0;
            @(negedge i_clk);
            i_rst_n = 1'b1;
        end
    endtask : reset_dut



    //========================================
    // Test Cases
    //========================================


    /*
     tb_krf_io_no_pipeline : load kernel values from the FIFO with no pipelining (i_rst_n held, toggled i_valid)
     */
    task automatic test1;
        ref reg i_clk;
        ref reg i_valid;
        ref reg i_rst_n;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output

        begin

            //reset signals
            i_kernels = '{0};
            i_krf_total = '{0};
            krf_total_cvrt = '{0};

            @(negedge i_clk);

            for (int i = 0 ; i < NUM_STATES ; i++) begin

                // Load a row
                //assert(std::randomize(i_kernels)); //NEED LICENSE
                if(i==0) begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end else if (i==1) begin
                    i_kernels = 64'h0123456789101112;
                end else if (i==2) begin
                    i_kernels = 64'hBEEF50B3CAFE6688;
                end else begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end
            
                //Save new kernel values
                i_krf_total[i] = i_kernels;
                krf_total_cvrt = krf_convert(i_krf_total);

                if(VERBOSE) begin
                    $display("Current kernel vals: 0x%X", i_kernels);
                    $display("All kernel vals: 0x%X", i_krf_total);
                end


                i_valid = 1'b1; //mark input as valid
                @(negedge i_clk);
                i_valid = 1'b0; // mark input as invalid to check output and make sure new row is loaded
                @(negedge i_clk); // let data appear at output (1 clock cycle)

                // check output
                if(krf_total_cvrt != o_kernels) begin
                    `uvm_error("tb_top", $sformatf("Test failed at i = %d\no_kernels = 0x%X ; expected = 0x%X",i,o_kernels, krf_total_cvrt));
                end
            end

            `uvm_info("tb_top", "Test tb_krf_io_no_pipeline passed", UVM_NONE);
        end

    endtask : test1


    /* 
        tb_krf_io_pipeline : load kernel values from the FIFO with pipelining (i_rst_n and i_valid held)
    */
    task automatic test2;
        ref reg i_clk;
        ref reg i_valid;
        ref reg i_rst_n;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output

        begin

            //reset signals
            i_kernels = '{0};
            i_krf_total = '{0};
            krf_total_cvrt = '{0};
            i_rst_n = 1'b1;

            @(negedge i_clk);
            i_valid = 1'b1; //input valid

            for (int i = 0 ; i < NUM_STATES ; i++) begin

                // Load a row
                //assert(std::randomize(i_kernels)); //NEED LICENSE
                if(i==0) begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end else if (i==1) begin
                    i_kernels = 64'h0123456789101112;
                end else if (i==2) begin
                    i_kernels = 64'hBEEF50B3CAFE6688;
                end else begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end

                @(negedge i_clk); //input new data / let data appear at output (1 clock cycle)

                //Save new kernel values
                i_krf_total[i] = i_kernels;
                krf_total_cvrt = krf_convert(i_krf_total);

                if(VERBOSE) begin
                    $display("Current kernel vals: 0x%X", i_kernels);
                    $display("All kernel vals: 0x%X", i_krf_total);
                end

                // check output
                if(krf_total_cvrt != o_kernels) begin
                    `uvm_error("tb_top", $sformatf("Test failed at i = %d\no_kernels = 0x%X ; expected = 0x%X",i,o_kernels, krf_total_cvrt))
                end

            end
                
            `uvm_info("tb_top", "Test tb_krf_io_pipeline passed", UVM_NONE);
        end

    endtask : test2



    /*
     tb_krf_invalid_load : load kernel values under invalid conditions (i_rst_n=1 i_valid=0, i_rst_n=0 i_valid=1). 
                           for all possible states. No pipelining.
     */
    task automatic test3;
        ref reg i_clk;
        ref reg i_valid;
        ref reg i_rst_n;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output

        begin

            //for each state: do it

            /*
            Attempt loading kernel values when i_rst_n=0, i_valid=1
            */
            i_kernels = 64'h45BEEF9CFECAC0FF;
            i_valid = 1'b1; 
            i_rst_n = 1'b0;
            @(negedge i_clk);

            // check output
            if(o_kernels != 64'h0) begin
                `uvm_error("tb_top", $sformatf("Test failed when i_rst_n=1, i_valid=1\no_kernels = 0x%X ; expected = 0x%X",o_kernels, 64'h0));
            end

            i_valid = 1'b0; 
            @(negedge i_clk);


            /*
            Attempt loading kernel values at each state when i_valid=0, i_rst_n=0
            */
            i_rst_n = 1'b0; //reset state machine
            @(negedge i_clk);
            i_rst_n = 1'b1; 
            
            //reset signals
            i_kernels = '{0};
            i_krf_total = '{0};
            krf_total_cvrt = '{0};

            @(negedge i_clk);

            for (int i = 0 ; i < NUM_STATES ; i++) begin

                /*
                New state
                */
                //assert(std::randomize(i_kernels)); //NEED LICENSE
                if(i==0) begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end else if (i==1) begin
                    i_kernels = 64'h0123456789101112;
                end else if (i==2) begin
                    i_kernels = 64'hBEEF50B3CAFE6688;
                end else begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end
            
                //Save new kernel values
                i_krf_total[i] = i_kernels;
                krf_total_cvrt = krf_convert(i_krf_total);

                if(VERBOSE) begin
                    $display("Current kernel vals: 0x%X", i_kernels);
                    $display("All kernel vals: 0x%X", i_krf_total);
                end


                i_valid = 1'b1; //mark input as valid
                @(negedge i_clk);

                /*
                Attempt to load new input (NOTE: this test is already done in the non-pipeline test cases)
                */
                i_valid = 1'b0; // mark input as invalid to check output and make sure new input is loaded
                @(negedge i_clk); // let data appear at output (1 clock cycle)

                // check output
                if(krf_total_cvrt != o_kernels) begin
                    `uvm_error("tb_top", $sformatf("Test failed at i = %d\no_kernels = 0x%X ; expected = 0x%X",i,o_kernels, krf_total_cvrt));
                end
            end
                
            `uvm_info("tb_top", "Test tb_krf_invalid_load passed", UVM_NONE);
        end

    endtask : test3






    /*
     tb_krf_overload : try loading additional values once the KRF is full
     */
    task automatic test4;
        ref reg i_clk;
        ref reg i_valid;
        ref reg i_rst_n;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output

        begin

            //for each state: do it

            i_rst_n = 1'b0; //reset state machine
            @(negedge i_clk);
            i_rst_n = 1'b1; 
            
            //reset signals
            i_kernels = '{0};
            i_krf_total = '{0};
            krf_total_cvrt = '{0};

            @(negedge i_clk);
            /*
              Fill KRF
            */
            for (int i = 0 ; i < NUM_STATES ; i++) begin

                // Load a row
                //assert(std::randomize(i_kernels)); //NEED LICENSE
                if(i==0) begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end else if (i==1) begin
                    i_kernels = 64'h0123456789101112;
                end else if (i==2) begin
                    i_kernels = 64'hBEEF50B3CAFE6688;
                end else begin
                    i_kernels = 64'h45BEEF9CFECAC0FF;
                end
            
                //Save new kernel values
                i_krf_total[i] = i_kernels;
                krf_total_cvrt = krf_convert(i_krf_total);

                if(VERBOSE) begin
                    $display("Current kernel vals: 0x%X", i_kernels);
                    $display("All kernel vals: 0x%X", i_krf_total);
                end


                i_valid = 1'b1; //mark input as valid
                @(negedge i_clk);
                i_valid = 1'b0; // mark input as invalid to check output and make sure new row is loaded
                @(negedge i_clk); // let data appear at output (1 clock cycle)

                // check output
                if(krf_total_cvrt != o_kernels) begin
                    `uvm_error("tb_top", $sformatf("Test failed at i = %d\no_kernels = 0x%X ; expected = 0x%X",i,o_kernels, krf_total_cvrt));
                    @(negedge i_clk); // let data appear at output
                    $finish(2);
                end
            end

            /*
              Try loading additional input
            */
            i_kernels = 64'hADD0ADD1ADD2ADD3;
            i_valid = 1'b1; //mark input as valid
            if(VERBOSE) begin
                $display("Attempt loading additional input: 0x%X", i_kernels);
            end
            @(negedge i_clk);
            i_valid = 1'b0; // mark input as invalid to check output and make sure new row is loaded
            @(negedge i_clk); // let data appear at output (1 clock cycle)

            // check output
            if(krf_total_cvrt != o_kernels) begin
                `uvm_error("tb_top", $sformatf("Test failed when loading additional input\no_kernels = 0x%X ; expected = 0x%X",o_kernels, krf_total_cvrt));
                @(negedge i_clk); // let data appear at output
                $finish(2);
            end
                
            `uvm_info("tb_top", "Test tb_krf_overload passed", UVM_NONE);
        end

    endtask : test4
endmodule