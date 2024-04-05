
#include "system.h"
#include "sc_trace.hpp"

#include "systemc.h"
#include <iostream>
#include <string>

// runtime configuration
int kernel_dim;
int hf_kernel_dim;

// global memory
uint8_t memory[MEM_SIZE];

// SystemC simulation
sc_tracer sc_tracer::tracer;

/** Matrix multiplier program. */
SC_MODULE(mat_mult) {
    SC_CTOR(mat_mult) {
        SC_THREAD(main);
    }

    void main() {
        // memory pointers
        uint8_t *subj_mem = &memory[MAT_ADDR];
        uint8_t *kern_mem = &memory[KERN_ADDR];
        uint8_t *out_mem = &memory[OUT_ADDR];

        // counters
        uint16_t r;
        uint16_t c;
        int kerneli;
        int i;
        int j;

        // results
        uint32_t res;

        // execute
        LOGF("[%s] writing to %08x, matrix is %dx%d", this->name(), OUT_ADDR, MAT_ROWS, MAT_COLS);
        POS_PROC(); // r = 0
        for (r = 0; r < MAT_ROWS; r++) {
            POS_PROC(); // r < MAT_ROWS

            POS_PROC(); // c = 0
            for (c = 0; c < MAT_COLS; c++) {
                POS_PROC(); // c < MAT_COLS

                // accumulate result
                res = 0;
                POS_PROC(); // res = 0

                // compute kernel dot product with neighborhood
                kerneli = 0;
                POS_PROC(); // kerneli = 0
                for (i = r - hf_kernel_dim; i <= r + hf_kernel_dim; i++) {
                    for (j = c - hf_kernel_dim; j <= c + hf_kernel_dim; j++) {
                        if (i >= 0 && i < MAT_ROWS && j >= 0 && j < MAT_COLS) {
                            res += (uint32_t)subj_mem[i*MAT_COLS + j] // matrix value is unsigned byte
                                * (uint32_t)kern_mem[kerneli]; // kernel value is signed byte
                        }
                        kerneli++;
                    }
                }

                // write result and increment cursor
                *out_mem = (uint8_t)res;
                out_mem++;

                POS_PROC(); // c++
            }

            POS_PROC(); // r++
        }

        LOGF("[%s] Done multiplying", this->name());
    }
};

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

    // matrix multiplier (CPU)
    mat_mult *matrix_multiplier = new mat_mult("matrix_multiplier");

    // =============================
    // ==== RUN THE SIMULATION =====
    // =============================
    sc_time startTime = sc_time_stamp();
    sc_start();
    sc_time stopTime = sc_time_stamp();

    std::cout << "Simulated for " << (stopTime - startTime) << std::endl;
    std::cout << "Executed " << (uint64_t)((uint64_t)(stopTime - startTime).to_double() / CC_PROC_PS) << " instructions." << std::endl;

    // final state
    memoryWrite(argv, memory);
    //memoryPrint(memory, kernel_dim);

    return 0;
}
