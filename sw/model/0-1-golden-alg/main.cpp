
#include "system.h"
#include "core.h"
#include "cluster.h"
#include "mat_mult_golden_alg.h"
#include "mat_mult_if.h"

#include "systemc.h"
#include <iostream>
#include <string>

int kernel_size;
int hf_kernel_size;
uint8_t memory[MEM_SIZE];

class memory_mod : public sc_module, public mem_if {

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

        mmIf->sendCmd(MM_CMD_KERN, kernel_size, kernel_size, UNUSED_ADDR, 0);
        std::cout << "Done kernel cmd" << std::endl;

        mmIf->sendPayload(KERN_ADDR, kernel_size, kernel_size);
        std::cout << "Done kernel payload" << std::endl;

        mmIf->sendCmd(MM_CMD_SUBJ, MAT_ROWS, MAT_COLS, UNUSED_ADDR, OUT_ADDR);
        std::cout << "Done subject cmd" << std::endl;

        mmIf->sendPayload(MAT_ADDR, MAT_ROWS, MAT_COLS);
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
    mat_mult_ga *matrix_multiplier = new mat_mult_ga("matrix_multiplier", memory);
    matrix_multiplier->memIf(*mem);

    // design parameters
    uint32_t n_clusters = MAX_N_CLUSTERS;
    uint32_t n_cores_per_cluster = MAX_N_CORES;
    uint32_t k_list[PACKET_BYTES];

    for (int i = 0; i < PACKET_BYTES; ++i) {
        k_list[i] = i;
    }

    // initialize clusters and cores
    cluster *clusters[MAX_N_CLUSTERS];
    core *cores[MAX_N_CLUSTERS * MAX_N_CORES];
    int i = 0;
    for (; i < n_clusters; ++i) {
        // initialize each cluster
        clusters[i] = new cluster(("cluster" + std::to_string(i)).c_str(),
            k_list + i, 1, // pointer to assigned values of k, number of assigned values
            n_cores_per_cluster); // number of cores

        // initialize each core
        int j = 0;
        for (; j < n_cores_per_cluster; ++j) {
            cores[j + i * MAX_N_CORES] = new core(("cluster" + std::to_string(i) + "core" + std::to_string(j)).c_str());
            clusters[i]->core_ifs[j](*cores[j + i * MAX_N_CORES]);
        }
        for (; j < MAX_N_CORES; ++j) {
            cores[j + i * MAX_N_CORES] = new core("dummy");
            clusters[i]->core_ifs[j](*cores[j + i * MAX_N_CORES]);
        }
        
        // connect to multiplier
        matrix_multiplier->cluster_ifs[i](*clusters[i]);
    }
    for (; i < MAX_N_CLUSTERS; ++i) {
        clusters[i] = new cluster("dummy", nullptr, 0, 0);
        matrix_multiplier->cluster_ifs[i](*clusters[i]);
    }

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
