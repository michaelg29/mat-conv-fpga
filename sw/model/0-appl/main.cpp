
#include "system.h"
#include "mat_mult.h"
#include "mat_mult_if.h"
#include "memory_if.h"

#include "systemc.h"
#include <iostream>
#include <string>

int kernel_size;
int hf_kernel_size;
uint8_t memory[MEM_SIZE];

class memory_mod : public sc_module, public memory_if {

    public:

        memory_mod(sc_module_name name, uint8_t *memory, uint64_t mem_size) : sc_module(name), memory(memory), mem_size(mem_size) {}

        bool write(uint64_t addr, uint64_t data) {
            if (!check_addr(addr)) return false;
            align_addr(addr);
            ((uint64_t*)memory)[addr] = data;
            return true;
        }

        bool read(uint64_t addr, uint64_t& data) {
            if (!check_addr(addr)) return false;
            align_addr(addr);
            data = ((uint64_t*)memory)[addr];
            return true;
        }

    private:

        uint8_t *memory;
        uint64_t mem_size;

        // align address to count by data width (64b/8B)
        void align_addr(uint64_t& addr) {
            addr >>= 3;
        }

        bool check_addr(uint64_t addr) {
            return addr < mem_size;
        }

};

/**
 * Module to issue commands to the matrix multiplier.
 */
SC_MODULE(mm_cmd) {

    sc_port<mat_mult_if> mmIf;

    SC_CTOR(mm_cmd) {
        SC_THREAD(do_mat_mult);
    }

    void do_mat_mult() {
        std::cout << "Starting" << std::endl;
        mmIf->reset();
        std::cout << "Done reset" << std::endl;

        mmIf->sendCmd(memory, MM_CMD_KERN, kernel_size, kernel_size, UNUSED_ADDR, 0);
        std::cout << "Done kernel cmd" << std::endl;

        mmIf->sendPayload(memory, KERN_ADDR, kernel_size, kernel_size);
        std::cout << "Done kernel payload" << std::endl;

        mmIf->sendCmd(memory, MM_CMD_SUBJ, MAT_ROWS, MAT_COLS, UNUSED_ADDR, OUT_ADDR);
        std::cout << "Done subject cmd" << std::endl;

        mmIf->sendPayload(memory, MAT_ADDR, MAT_ROWS, MAT_COLS);
        std::cout << "Done subject payload" << std::endl;
    }

}; // SC_MODULE(mm_cmd)

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

    // memory interface
    memory_mod *mem = new memory_mod("mem", memory, MEM_SIZE);

    // matrix multiplier
    mat_mult *matrix_multiplier = new mat_mult("matrix_multiplier");
    matrix_multiplier->mem_if(*mem);

    // command issuer
    mm_cmd *cpu = new mm_cmd("cpu");
    cpu->mmIf(*matrix_multiplier);

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

    return 0;
}
