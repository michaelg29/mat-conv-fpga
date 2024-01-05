
#include "system.h"
#include "mat_mult_golden_wait.h"
#include "mat_mult_if.h"

#include "systemc.h"
#include <iostream>
#include <string>
#include "sc_trace.hpp"

sc_tracer sc_tracer::tracer;

int kernel_size;
int hf_kernel_size;
uint8_t memory[MEM_SIZE];

int sc_main(int argc, char* argv[]) {
    if (!parseCmdLine(argc, argv, memory, &kernel_size)) {
        return 1;
    }
    
    // initial state
    std::cout << "Matrix size: " << MAT_ROWS << "x" << MAT_COLS << ", kernel size: " << kernel_size << "x" << kernel_size << std::endl;
    hf_kernel_size = kernel_size >> 1;
    memoryPrint(memory, kernel_size);
    
    // =====================================
    // ==== CREATE AND CONNECT MODULES =====
    // =====================================
    
    // memory interface (top-level interface with the CPU)
    simple_memory_mod<uint64_t> *mem = new simple_memory_mod<uint64_t>("mem", memory, MEM_SIZE);
    
    // matrix multiplier
    mat_mult_wait *matrix_multiplier = new mat_mult_wait("matrix_multiplier");
    matrix_multiplier->mem_if(*mem);
    
    // command issuer (CPU)
    mat_mult_cmd *cpu = new mat_mult_cmd("cpu", memory, kernel_size);
    cpu->mm_if(*matrix_multiplier);
    matrix_multiplier->cmd_if(*cpu);
    

    // =============================
    // ==== RUN THE SIMULATION =====
    // =============================
    sc_time startTime = sc_time_stamp();
    sc_start();
    sc_time stopTime = sc_time_stamp();

    cout << "Simulated for " << (stopTime - startTime) << endl;

    // final state
    memoryWrite(argv, memory);
    memoryPrint(memory, kernel_size);
    sc_tracer::close();
    
    std::cout << "Press enter to continue." << std::endl;
    std::string c;
    std::getline(std::cin, c);
    return 0;
}
