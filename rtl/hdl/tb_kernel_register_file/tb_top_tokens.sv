`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 3, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TESTS_TO_RUN = "tb_krf_io_no_pipeline,tb_krf_io_pipeline", // Name of test cases to run
        parameter string SEPARATOR = "," // Separator for the TESTS_TO_RUN string (must be a character)
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

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

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_krf_io_no_pipeline",
        "tb_krf_io_pipeline"
    };

    initial begin

        //Variables
        automatic string test_case = "";
        automatic int curr_len = 0;

        //Split test cases string into tokens
        automatic string test_queue[];
        strtok(TESTS_TO_RUN, SEPARATOR, test_queue);

        if(VERBOSE) begin
            $display("test_queue: %p", test_queue);
        end

        //Loop through all possible test cases
        foreach (TEST_CASES[i]) begin

            //Get current test case name
            test_case = TEST_CASES[i];

            //Check size of list of tests to run
            curr_len = test_queue.size();

            //If no more test to run: stop
            if(curr_len == 0) break;

            //Remove occurences of test_case in list of tests left to run
            test_queue = test_queue.find(s) with (uvm_re_match(test_case, s) != 0);

            //if list is smaller, test case was present so run
            if(curr_len > test_queue.size()) begin

                $display("===> Running Test: %s", TEST_CASES[i]);
                
                case (i+1)
                    1 : begin      
                        test1(.i_clk(i_clk),
                            .i_valid(i_valid),
                            .i_rst(i_rst),
                            .i_kernels(i_kernels),
                            .o_kernels(o_kernels));
                        end
                    2 : begin
                        test2(.i_clk(i_clk),
                            .i_valid(i_valid),
                            .i_rst(i_rst),
                            .i_kernels(i_kernels),
                            .o_kernels(o_kernels));
                        end
                    default : $display("WARNING: %d is not a valid task ID", i);
                endcase
                
            end

        end

        `uvm_info("tb_top", "All tests passed", UVM_NONE);
        $finish(0);
        
    end



    //========================================
    // Functions
    //========================================

    /*
        String tokenizer
    */
    function automatic strtok(string s, string sep, ref string oarray[]);

        automatic int start = 0;
        automatic int stop = 0;
        automatic int last_token = 1; //last token present flag

        string array [];

        //Tokenize using separator
        foreach(s[i]) begin
            
            if(s[i]==sep) begin
                //edge cases:
                if(start == i) begin
                    start = i+1;
                    continue;
                end else if (i==s.len()-1) begin
                    last_token = 0;
                end

                //Push to token array
                array = new [array.size() + 1] (array);
                array[array.size() - 1] = s.substr(start, i-1);

                //Update start
                start = i+1;
            end
        end

        if(last_token == 1) begin
            //Push last token to array
            array = new [array.size() + 1] (array);
            array[array.size() - 1] = s.substr(start, s.len()-1);
        end

        //Assign dyamic array to ref
        oarray = array;

    endfunction


    /*
        Check the current KRF output to the input values
    */
    function logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_convert;
        input [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total;

        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt;

        krf_total_cvrt[0] = i_krf_total[0][7:3];

        krf_total_cvrt[1] = {i_krf_total[0][2:0], i_krf_total[1][7:6]};

        krf_total_cvrt[2] = i_krf_total[1][5:1];

        krf_total_cvrt[3] = {i_krf_total[1][0:0], i_krf_total[2][7:4]};

        krf_total_cvrt[4] = {i_krf_total[2][3:0], i_krf_total[3][7:7]};
        
        
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


    // tb_krf_io_no_pipeline :load kernel values from the FIFO with no pipelining (i_rst held, toggled i_valid)
    task automatic test1;
        ref reg i_clk;
        ref reg i_valid;
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output

        begin

            for (int j = 0 ; j < NUM_REPS ; j++) begin

                @(negedge i_clk);
                i_rst = 1'b1; //reset state machine -> ready to program
                
                //reset signals
                i_kernels = '{0};
                i_krf_total = '{0};
                krf_total_cvrt = '{0};

                @(negedge i_clk);

                for (int i = 0 ; i < 4 ; i++) begin

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
                    //i_kernels = 64'hBEEF50B3CAFE66C2; //first BEEF is top-left two bytes, last B3 is third value of second row
                    
                    //Save new kernel values
                    i_krf_total[i] = i_kernels;
                    krf_total_cvrt = krf_convert(i_krf_total);

                    if(VERBOSE) begin
                        $display("Current kernel vals: 0x%X", i_kernels);
                        $display("All kernel vals: 0x%X", i_krf_total);
                    end


                    i_valid = 1'b1;
                    @(negedge i_clk);
                    i_valid = 1'b0; // check output and make sure new row is loaded

                    @(posedge i_clk); // 1 clock cycle to output the data
                    @(negedge i_clk); // let data appear at output

                    // check pixels
                    // variable part select
                    if(krf_total_cvrt != o_kernels) begin
                        `uvm_error("tb_top", $sformatf("Test 1 failed at j = %d, i = %d\no_kernels = 0x%X ; expected = 0x%X",j,i,o_kernels, krf_total_cvrt))
                        @(negedge i_clk); // let data appear at output
                        $finish(2);
                    end
                end
                
            end

            `uvm_info("tb_top", "Test tb_krf_io_no_pipeline passed", UVM_NONE);
        end

    endtask : test1


    // tb_krf_io_pipeline :load kernel values from the FIFO with pipelining (i_rst and i_valid held)
    task automatic test2;
        ref reg i_clk;
        ref reg i_valid;
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output

        begin

            for (int j = 0 ; j < NUM_REPS ; j++) begin
                @(negedge i_clk);
                i_rst = 1'b1; //reset state machine -> ready to program
                @(negedge i_clk);

                for (int i = 0 ; i < 4 ; i++) begin

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
                    //i_kernels = 64'hBEEF50B3CAFE66C2; //first BEEF is top-left two bytes, last B3 is third value of second row
                    
                    //Save new kernel values
                    i_krf_total[i] = i_kernels;
                    krf_total_cvrt = krf_convert(i_krf_total);

                    if(VERBOSE) begin
                        $display("Current kernel vals: 0x%X", i_kernels);
                        $display("All kernel vals: 0x%X", i_krf_total);
                    end


                    i_valid = 1'b1;
                    @(negedge i_clk);
                    i_valid = 1'b0; // check output and make sure new row is loaded

                    @(posedge i_clk); // 1 clock cycle to output the data
                    @(negedge i_clk); // let data appear at output

                    // check pixels
                    // variable part select
                    if(krf_total_cvrt != o_kernels) begin
                        `uvm_error("tb_top", $sformatf("Test 1 failed at i = %d\r\o_kernels = 0x%X ; expected = 0x%X",i,o_kernels, krf_total_cvrt))
                        @(negedge i_clk); // let data appear at output
                        $finish(2);
                    end
                end
                
            end
                
            `uvm_info("tb_top", "Test tb_krf_io_pipeline passed", UVM_NONE);
        end

    endtask : test2

endmodule