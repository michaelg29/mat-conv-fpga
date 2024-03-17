`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top
    #(
        parameter KERNEL_SIZE = 5,
        parameter FIFO_WIDTH = 8,
        parameter int NUM_REPS = 2, //Number of times each test shall be reapeated with different values
        parameter int SEED = 0, //Seed for the random input generation
        parameter int VERBOSE = 0, //Enable verbosity for debug
        parameter string TC= "tb_cluster_mac_io_pipeline", // Name of test case to run

        parameter ROUNDING = 3'b100,
        parameter READ_DELAY = 2, //delay between valid address and valid output data of CMC
        parameter CORE_DELAY = 2, //delay from input to output of core
        parameter NUM_PIXEL_REPS = 2
    );

    import uvm_pkg::*;

    //Set seed for randomization
    bit [31:0] dummy = $urandom(SEED);

    //========================================
    // Signals
    //========================================
    
    reg i_clk;

    /*
    KRF signals
    */
    reg i_valid;
    reg i_rst;
    logic [FIFO_WIDTH-1:0][7:0] i_kernels;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]
    const int NUM_STATES = (KERNEL_SIZE*KERNEL_SIZE - 1)/FIFO_WIDTH + 1; //round up trick
    
    /*
    Cluster feeder
    */
    reg [FIFO_WIDTH-1:0][7:0] i_pixels;
    reg i_new;
    reg i_sel;
    reg [KERNEL_SIZE-1:0][7:0] o_pixels;


    /*
    Cores signals
    */
    reg i_en; //shared by all cores
    logic [KERNEL_SIZE-1:0][7:0] i_pixels_cores; //connect to o_pixels of cluster feeder with one clock cycle delay
    //logic [KERNEL_SIZE-1:0][7:0] i_kernels; //connect to o_kernels of KRF directly
    //logic [17:0] i_sub; //constant 0 for all cores
    logic [KERNEL_SIZE-1:0][17:0] o_res; //output of each core

    // Variables declarations (packed arrays)
    var longint i1 = 0; // 5 pixels
    var longint j1 = 0; // 5 kernel values
    var longint k1 = 0; // sub
    var [READ_DELAY+CORE_DELAY-1:0][KERNEL_SIZE-1:0][43:0] oreg = 0; //calculate result at input of cluster feeder, get output at output of cores

    // use time to get 64-bit signed int (only need 40-bits for i and j)
    var longint i;
    var longint j;
    var longint k;


    /*
    Delays
    */
    logic [READ_DELAY-1:0][KERNEL_SIZE-1:0][7:0] pixels_delay; //delays from cluster feeder to cores



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
    
    //KRF
    krf krf_dut(
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


    // Cluster feeder
    cluster_feeder cluster_feeder_dut(
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


    //Cores
    genvar g;
    generate;
    for(g=0 ; g<KERNEL_SIZE ; g++) begin

        //Connect core
        core #(
            .i_round({41'b0,ROUNDING})
        )
        core_dut(
            .i_clk      (i_clk),
            .i_en       (i_en),
            .i_s0       (i_pixels_cores[0]),
            .i_s1       (i_pixels_cores[1]),
            .i_s2       (i_pixels_cores[2]),
            .i_s3       (i_pixels_cores[3]),
            .i_s4       (i_pixels_cores[4]),

            .i_k0       (o_kernels[g][0]),
            .i_k1       (o_kernels[g][1]),
            .i_k2       (o_kernels[g][2]),
            .i_k3       (o_kernels[g][3]),
            .i_k4       (o_kernels[g][4]),
            .i_sub      (18'h0), //constant 0
            .o_res      (o_res[g])
        );
    end
    endgenerate


    //Delay from cluster feeder output to cores
    assign pixels_delay[0] = o_pixels; //feed into pixels delay pipeline 
    always @(posedge i_clk) begin
        if(READ_DELAY > 1) begin
            pixels_delay[READ_DELAY-1:1] <= pixels_delay[READ_DELAY-2:0];
        end 
    end
    assign i_pixels_cores = pixels_delay[READ_DELAY-1]; //feed output of pixels delay pipeline into cores


    //========================================
    // Testbench
    //========================================

    //Array of test cases names
    //NOTE: test number must match with test name index
    string TEST_CASES[] = {
        "tb_cluster_mac_io_pipeline"
        //TODO
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
                    reset_dut(
                        .i_clk(i_clk), 
                        .i_rst(i_rst), 
                        .i_kernels(i_kernels)
                        );

                    case (i+1)
                        1 : begin      
                            test1(
                                .i_clk(i_clk),

                                //KRF signals
                                .i_valid(i_valid),
                                .i_rst(i_rst),
                                .i_kernels(i_kernels),
                                .o_kernels(o_kernels)

                                //Cluster feeder signals
                            );
                            end
                        //2 : begin
                        //    test2();
                        //    end
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

    /*
        Reset DUT
    */
    task automatic reset_dut;
        ref reg i_clk;    
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        begin


            //KRF RESET
            //Load 0s
            i_kernels = '{0};
            i_valid = 1'b1;

            //Reset state machine and outputs
            i_rst = 1'b1;
            @(negedge i_clk);

            i_rst = 1'b0;
            i_valid = 0'b0;
            @(negedge i_clk);
        end
    endtask : reset_dut


    /*
        Load kernel values into KRF
    */
    task automatic load_kernel_values;

        //KRF inputs/outputs
        ref reg i_clk;       
        ref reg i_valid;
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        logic [3:0][FIFO_WIDTH-1:0][7:0] i_krf_total; //stacked inputs of KRF
        logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] krf_total_cvrt; // Convert krf_total to easily map to output


        begin
            `uvm_info("tb_top", "Loading Kernel values into KRF", UVM_NONE);
            
            //reset signals
            i_pixels = '{0};
            i_kernels = '{0};
            i_krf_total = '{0};
            krf_total_cvrt = '{0};
            i_en = 0;

            @(negedge i_clk);

            // Enable the core
            i_en = 1;

            i_rst = 1'b1; //reset state machine -> ready to program
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
                    @(negedge i_clk); // let data appear at output
                    $finish(2);
                end
            end

            i_rst = 1'b0; //done programming
            i_valid = 1'b0; //input invalid

            `uvm_info("tb_top", "Kernel values successfully loaded", UVM_NONE);

        end


    endtask : load_kernel_values



    //========================================
    // Test Cases
    //========================================


    /*
     tb_cluster_mac_io_pipeline : load kernel in KRF, then load pixel values in cluster feeder and checks cores output
     */
    task automatic test1;

        //Shared inputs
        ref reg i_clk;

        //KRF inputs/outputs       
        ref reg i_valid;
        ref reg i_rst;
        ref logic [FIFO_WIDTH-1:0][7:0] i_kernels;
        ref logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][7:0] o_kernels; //[kernel row][kernel value in row][bit in kernel value]

        //Cluster feeder 


        //Cores output
        longint mac = 0;


        //Load pixel values and check cores output (combined loop)
        const int NUM_CLUSTER_FEEDER_ITER = FIFO_WIDTH-KERNEL_SIZE+1; //number iterations to load pixels into cluster feeder
        const int NUM_CORE_ITER = READ_DELAY+CORE_DELAY; //Need iterations from previous pixel load and current ones
        int NUM_ITER = 0;

        //Number of cycles determined by longest delay
        if(NUM_CORE_ITER > NUM_CLUSTER_FEEDER_ITER) begin
            NUM_ITER = NUM_CORE_ITER;
        end else begin
            NUM_ITER = NUM_CLUSTER_FEEDER_ITER;
        end

        begin


            //Iterate over random kernel values
            //TODO

            //Load kernel values
            load_kernel_values(
                .i_clk(i_clk),
                .i_valid(i_valid),
                .i_rst(i_rst),
                .i_kernels(i_kernels),
                .o_kernels(o_kernels)
                );


            @(negedge i_clk);

            //For all combinations of pixels
            for(int i = 0 ; i < NUM_PIXEL_REPS; i++) begin

                //Random pixel values
                i_pixels = 64'hBEEF50B3CAFE6688;
                //assert(std::randomize(i_pixels)); //NEED LICENSE

                `uvm_info("tb_top", $sformatf("(%dth) Loading pixels into cluster feeder", i), UVM_NONE);
                for (int j = 0 ; j < NUM_ITER ; j++) begin

                    /*
                        Cluster feeder Logic
                    */
                    if(j==0) begin
                        i_sel = 1'b1; // parallel load
                        i_new = 1'b1; // pipeline shall load
                    end else begin
                        //Shift pixels
                        i_sel = 1'b0; // switch to serial load
                        i_new = 1'b0; // pipeline shall shift
                    end

                    //delay
                    @(negedge i_clk); // let data appear at output


                    // check cluster feeder output pixels
                    // variable part select
                    if(i_pixels[j+:5] != o_pixels) begin
                        `uvm_error("tb_top", $sformatf("Test 1 failed at i = %d, j = %d\no_pixels = 0x%X ; expected = 0x%X",i,j,o_pixels, i_pixels[j+:5]))
                        @(negedge i_clk); // let data appear at output
                        $finish(2);
                    end


                    /*
                        Cores logic
                    */
                    //Shift oreg
                    for (int k = READ_DELAY+CORE_DELAY-2; k >= 0 ; k--) begin
                        oreg[k+1] = oreg[k];
                    end

                    //Calculations for each core
                    for (int core = 0 ; core < KERNEL_SIZE ; core++) begin

                        // Calculate value that should be obtained from current input pixels
                        mac = 0; //sub is 0
                        mac += ROUNDING;
                        for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                            mac += signed'(o_kernels[core][s]) * signed'({1'b0,i_pixels[s+j]});
                        end
                        oreg[0][core] = mac;


                        if(i+j >= NUM_CORE_ITER) begin //need to wait for first core output
                            // Compare output to valid result
                            if(oreg[READ_DELAY+CORE_DELAY-1][core][20:3] != o_res[core]) begin
                                `uvm_error("tb_top", $sformatf("Test failed at i = %d ; j = %d ; core = %d\no_res = %d ; expected = %d",i,j,core,signed'(o_res[core]),signed'(oreg[READ_DELAY-1][core][20:3])));
                                @(negedge i_clk);
                                $finish(2);
                            end
                        end

                    end

                end

                `uvm_info("tb_top", "Pixel values successfully loaded to cluster feeder", UVM_NONE);

            end


            `uvm_info("tb_top", $sformatf("Extra %d clock cycles to check final outputs of cores", NUM_CORE_ITER), UVM_NONE);

            //Last iterations to verify the final outputs of cores
            //The -1 in the loop limit is due to the fact that one clock cycle was used
            //to input the pixels, which is accounted for in the NUM_CORE_ITER
            for(int i = 0 ; i < NUM_CORE_ITER-1 ; i++) begin

                //delay
                @(negedge i_clk); // let data appear at output

                /*
                    Cores logic
                */
                //Shift oreg
                for (int k = READ_DELAY+CORE_DELAY-2; k >= 0 ; k--) begin
                    oreg[k+1] = oreg[k];
                end

                for (int core = 0 ; core < KERNEL_SIZE-1 ; core++) begin

                    if(NUM_ITER+i < FIFO_WIDTH-KERNEL_SIZE+1) begin //stop calculating oreg once all inputs have been iterated over
                        // Calculate value that should be obtained from current input pixels
                        mac = 0; //sub is 0
                        mac += ROUNDING;
                        for (int s = 0 ; s < KERNEL_SIZE ; s++) begin
                            mac += signed'(o_kernels[core][s]) * signed'({1'b0,i_pixels[NUM_ITER+i+s]});
                        end
                        oreg[0][core] = mac;
                    end

                    // Compare output to valid result
                    if(oreg[READ_DELAY+CORE_DELAY-1][core][20:3] != o_res[core]) begin
                        `uvm_error("tb_top", $sformatf("Test failed at i = %d ; core = %d\no_res = 0x%X ; expected = 0x%X",i,core,signed'(o_res[core]),signed'(oreg[READ_DELAY-1][core][20:3])));
                        @(negedge i_clk);
                        $finish(2);
                    end
                    
                end
            end
                
            `uvm_info("tb_top", "Test tb_cluster_mac_io_pipeline passed", UVM_NONE);

        end

    endtask : test1


endmodule