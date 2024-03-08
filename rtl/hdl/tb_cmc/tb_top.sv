`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 3, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_cmc_mem_rw_no_pipeline", // Name of test case to run

        parameter MIN_ADDR = 11'h0,
        parameter MAX_ADDR = 11'h7FF,
        parameter WRITE_DELAY = 4, //delay between valid address and valid input data
        parameter READ_DELAY = 2 //delay between valid address and valid output data
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    reg i_clk;
    reg i_en;

    logic i_val;
    logic [10:0] i_addr;
    logic [KERNEL_SIZE-1:0][17:0] i_core;
    logic [KERNEL_SIZE-1:0][17:0] o_core;
    logic [17:0] o_pixel;

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

    //TODO fix port naming
    cmc DUT(
        .i_clk(i_clk),
        .i_en(i_en),

        .i_val(i_val),
        .i_addr(i_addr),
        .i_core0(i_core[0]),
        .i_core1(i_core[1]),
        .i_core2(i_core[2]),
        .i_core3(i_core[3]),
        .i_core4(i_core[4]),

        .o_core0(o_core[0]),
        .o_core1(o_core[1]),
        .o_core2(o_core[2]),
        .o_core3(o_core[3]),
        .o_core4(o_core[4])

        //.o_pixel(o_pixel)
    );
    //TODO remove this workaround once CMC is fixed
    always @(posedge i_clk) begin
        o_pixel <= i_core[4];
    end

    //Always enabled
    assign i_en = 1'b1;


    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_cmc_mem_rw_no_pipeline",
        "tb_cmc_mem_rw_random_pipeline"
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
                                .i_val(i_val),
                                .i_addr(i_addr),
                                .i_core(i_core),
                                .o_core(o_core),
                                .o_pixel(o_pixel)
                            );
                            end
                        2 : begin
                            test2(
                                .i_clk(i_clk),
                                .i_val(i_val),
                                .i_addr(i_addr),
                                .i_core(i_core),
                                .o_core(o_core),
                                .o_pixel(o_pixel)
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
            //TODO
        end
    endtask : reset_dut



    //========================================
    // Test Cases
    //========================================


    /*
     tb_cmc_mem_rw_no_pipeline : perform read/write to address range and checks if read==write value
     */
    task automatic test1;
        ref reg i_clk;
        ref logic i_val;
        ref logic [10:0] i_addr;
        ref logic [KERNEL_SIZE-1:0][17:0] i_core;
        ref logic [KERNEL_SIZE-1:0][17:0] o_core;
        ref logic [17:0] o_pixel;

        var longint addr;
        var int port;
        logic [KERNEL_SIZE:0][17:0] o_expected;

        begin

            // Reset all signals to 0
            i_val = 0;
            i_addr = 0;
            i_core = 0;
            @(negedge i_clk);

            //First port output is always 0
            o_expected[0] = 0;

            // Loop through all addresses
            for(addr = MIN_ADDR ; addr <= MAX_ADDR ; addr++) begin

                // Loop through all ports
                for(port = 0 ; port < KERNEL_SIZE ; port++) begin

                    //Calculate input value (address + port number)
                    i_core[port] = addr+port;
                    o_expected[port+1] = addr+port;

                    //Perform write (4 clock cycles delay)
                    i_addr = addr[10:0];
                    i_core[port] = addr+port;
                    i_val = 1'b1;
                    @(negedge i_clk);
                    //TODO: i_val = 1'b0;

                    //Wait for write data
                    for(int i=0; i<WRITE_DELAY; i++) @(negedge i_clk);

                    if(port == (KERNEL_SIZE-1)) begin //if last port
                        //Perform read (no delay, data is bypassed)
                    end else begin //if other ports
                        //Perform read (2 clock cycles delay)
                        i_val = 1'b1;
                        @(negedge i_clk);
                        //TODO: i_val = 1'b0;

                        //Wait for read data
                        for(int i=0; i<READ_DELAY; i++) @(negedge i_clk);
                    end


                    //Check result
                    if(o_expected != {o_core,o_pixel}) begin
                        `uvm_error("tb_top", $sformatf("Test failed at addr = 0x%X ; port = %d\noutput = 0x%X ; expected = 0x%X",addr,port,{o_core,o_pixel},o_expected));
                        @(negedge i_clk);
                        $finish(2);
                    end

                end

            end

        end

    endtask : test1


    /*
      tb_cmc_mem_rw_random_pipeline : perform read/write to address range and checks if read==write value
     */
    task automatic test2;
        ref reg i_clk;
        ref logic i_val;
        ref logic [10:0] i_addr;
        ref logic [KERNEL_SIZE-1:0][17:0] i_core;
        ref logic [KERNEL_SIZE-1:0][17:0] o_core;
        ref logic [17:0] o_pixel;

        var longint addr;
        var int port;
        var int randval;
        logic [MAX_ADDR-MIN_ADDR:0][KERNEL_SIZE:0][17:0] o_expected; 

        begin

            // Reset all signals to 0
            i_addr = 0;
            i_core = 0;
            i_val = 1'b0;
            @(negedge i_clk);

            //Next inputs are valid
            i_val = 1'b1;

            // Loop through all addresses to write (need +WRITE_DELAY due to timing delays)
            for(addr = MIN_ADDR ; addr <= MAX_ADDR+WRITE_DELAY ; addr++) begin

                //Generate random input
                randval = addr+port;
                i_core = {{18{1'b0}},{(KERNEL_SIZE-1){randval[17:0]}}}; //first output port is always 0
                //assert(std::randomize(i_val)); //NEED LICENSE

                //Save output for latest comparison
                o_expected[addr]= i_val;

                //Give addr
                i_addr = addr;
                if(MAX_ADDR-addr < WRITE_DELAY) begin
                    //Done with all addresses, still need to give inputs
                    i_val = 1'b0;
                end

                //Give input
                if(addr-MIN_ADDR >= WRITE_DELAY) begin //input is only valid after WRITE_DELAY clock cycles, need to wait
                    i_core = o_expected[addr-WRITE_DELAY];
                end
                @(negedge i_clk);

            end


            //Next outputs are valid
            i_val = 1'b1;

            // Loop through all addresses to read
            for(addr = MIN_ADDR ; addr <= MAX_ADDR+READ_DELAY ; addr++) begin

                //Give addr
                if(MAX_ADDR-addr < READ_DELAY) begin
                    //Done with all addresses, still wait for next outputs
                    i_val = 1'b0;
                end

                //Get output
                @(negedge i_clk);
                if(addr-MIN_ADDR >= READ_DELAY) begin //output is only valid after READ_DELAY clock cycles, need to wait

                    //Check result
                    if(o_expected[addr] != {o_core,o_pixel}) begin
                        `uvm_error("tb_top", $sformatf("Test failed at addr = 0x%X\noutput = 0x%X ; expected = 0x%X",addr,{o_core,o_pixel},o_expected[addr]));
                        @(negedge i_clk);
                        $finish(2);
                    end

                end

            end

        end

    endtask : test2


endmodule