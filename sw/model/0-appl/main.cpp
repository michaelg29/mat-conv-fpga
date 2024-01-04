
#include "system.h"
#include "mat_mult.h"
#include "mat_mult_if.h"
#include "memory_if.hpp"

#include "systemc.h"
#include <iostream>
#include <string>

int kernel_dim;
int hf_kernel_dim;
uint8_t memory[MEM_SIZE];

sc_tracer sc_tracer::tracer;

int sc_main(int argc, char* argv[]) {
    if (!parseCmdLine(argc, argv, memory, &kernel_dim)) {
        return 1;
    }

    // initial state
    std::cout << "Matrix size: " << MAT_ROWS << "x" << MAT_COLS << ", kernel size: " << kernel_dim << "x" << kernel_dim << std::endl;
    hf_kernel_dim = kernel_dim >> 1;
    memoryPrint(memory, kernel_dim);

    // =====================================
    // ==== CREATE AND CONNECT MODULES =====
    // =====================================

    // memory interface
    simple_memory_mod<uint64_t> *mem = new simple_memory_mod<uint64_t>("mem", memory, MEM_SIZE);

    // matrix multiplier
    mat_mult *matrix_multiplier = new mat_mult("matrix_multiplier");
    matrix_multiplier->mem_if(*mem);

    // command issuer (CPU)
    mat_mult_cmd *cpu = new mat_mult_cmd("cpu", memory, kernel_dim);
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
    memoryPrint(memory, kernel_dim);

    return 0;
}
