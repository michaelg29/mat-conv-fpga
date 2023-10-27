
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


    // Design optimization parameters
    uint8_t kernel_dim = MAX_KERN_DIM;
    uint32_t n_clusters = MAX_N_CLUSTERS; //Number of clusters (must be a power of 2)
    uint32_t n_cores_per_cluster = MAX_N_CORES;
    uint32_t payload_packet_size = PACKET_BYTES;   //Total number of bytes (pixels) received per payload packet (might be bigger than 64-bit if buffered)

    // Calculated design parameters
    uint32_t n_groups_per_cluster = (payload_packet_size + (kernel_dim - 1)) / n_clusters; //Number of groups to be processed for each cluster (NOTE: the division must yield an integer)
    
    /*UNUSED*/
    uint32_t cluster_input_size = payload_packet_size / n_clusters + (kernel_dim - 1); //Size of the dispatched grouped, which is also the size of each groups made when dispatching the input pixels
    uint32_t total_mem = PIXEL_SIZE * (kernel_dim - 1) * (MAT_COLS - 2*(kernel_dim-1)); //Total memory required for all the subresults
    uint32_t total_mem_per_cluster = total_mem / n_clusters; //Total local memory required for each cluster
    uint32_t num_input_pixels = (kernel_dim - 1) + payload_packet_size;  //Number of pixels to dispatch at once ((kernel_dim - 1) is for the pixels shared from the previous data received)

    //TODO clusters shall have a command to receive from the payload packet + transferred pixels (not just 64 bits essentially)
    //DONE (see receiveData)

    //TODO clusters should NOT be responsible for buffering the last two pixels, since only the first cluster
    //will receive those. Only the top-level must take care of that. Clusters are simply computing what they are receiving.
    //DONE (see matmul and receiveData)

    // memory interface (top-level interface with the CPU)
    memory_mod *mem = new memory_mod("mem", memory, MEM_SIZE);
    
    // matrix multiplier (top-level)
    mat_mult_ga *matrix_multiplier = new mat_mult_ga("matrix_multiplier", 
                                                    memory, 
                                                    n_clusters,
                                                    n_cores_per_cluster,
                                                    kernel_dim,
                                                    payload_packet_size,
                                                    n_groups_per_cluster);
    matrix_multiplier->memIf(*mem);


    // initialize clusters and cores
    cluster *clusters[n_clusters];
    core *cores[n_clusters * n_cores_per_cluster];

    for (int i = 0; i < n_clusters; i++) {
        // initialize each cluster
        clusters[i] = new cluster(("cluster" + std::to_string(i)).c_str(),
                                    i*n_groups_per_cluster, //start group offset
                                    n_groups_per_cluster,   //number of groups to process
                                    n_cores_per_cluster,    //number of cores
                                    kernel_dim);            //dimension of the kernel


        // initialize each core for each cluster
        int j = 0;
        for (; j < n_cores_per_cluster; j++) {
            cores[j + i * n_cores_per_cluster] = new core(("cluster" + std::to_string(i) + "core" + std::to_string(j)).c_str());
            clusters[i]->core_ifs[j](*cores[j + i * n_cores_per_cluster]);
        }
        
        // connect each cluster to the matrix multiplier (top-level)
        matrix_multiplier->cluster_ifs[i](*clusters[i]);
    }

    // command issuer (CPU)
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
