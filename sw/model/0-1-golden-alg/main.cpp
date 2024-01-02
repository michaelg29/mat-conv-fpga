
#include "system.h"
#include "core.h"
#include "cluster.h"
#include "mat_mult_golden_alg.h"
#include "mat_mult_if.h"
#include "sc_trace.hpp"

#include "systemc.h"
#include <iostream>
#include <string>

int kernel_dim;
uint8_t memory[MEM_SIZE];

sc_tracer sc_tracer::tracer;

int sc_main(int argc, char* argv[]) {
    if (!parseCmdLine(argc, argv, memory, &kernel_dim)) {
        return 1;
    }

    // initial state
    std::cout << "Subject size: " << MAT_ROWS << "x" << MAT_COLS << ", kernel size: " << kernel_dim << "x" << kernel_dim << std::endl;
    memoryPrint(memory, kernel_dim);

    // ============================
    // ==== DESIGN PARAMETERS =====
    // ============================

    // Design optimization parameters
    uint32_t n_clusters = MAX_N_CLUSTERS; // number of clusters (must be a power of 2)
    uint32_t n_cores_per_cluster = kernel_dim;
    uint32_t payload_packet_size = PACKET_BYTES; // total number of bytes (pixels) received per payload packet (might be bigger than 64-bit if buffered)

    // Calculated design parameters
    uint32_t n_groups_per_cluster = (payload_packet_size + (kernel_dim - 1)) / n_clusters; // number of groups to be processed for each cluster (NOTE: the division must yield an integer)

    /*UNUSED*/
    uint32_t cluster_input_size = payload_packet_size / n_clusters + (kernel_dim - 1); //Size of the dispatched grouped, which is also the size of each groups made when dispatching the input pixels
    uint32_t total_mem = PIXEL_SIZE * (kernel_dim - 1) * (MAT_COLS - 2*(kernel_dim-1)); //Total memory required for all the subresults
    uint32_t total_mem_per_cluster = total_mem / n_clusters; //Total local memory required for each cluster
    uint32_t num_input_pixels = (kernel_dim - 1) + payload_packet_size;  //Number of pixels to dispatch at once ((kernel_dim - 1) is for the pixels shared from the previous data received)

    // initial trace
    sc_tracer::trace(n_clusters, "top", "n_clusters");
    sc_tracer::trace(n_cores_per_cluster, "top", "n_cores_per_cluster");
    sc_tracer::trace(payload_packet_size, "top", "payload_packet_size");
    sc_tracer::trace(n_groups_per_cluster, "top", "n_groups_per_cluster");

    // =====================================
    // ==== CREATE AND CONNECT MODULES =====
    // =====================================

    // memory interface (top-level interface with the CPU)
    simple_memory_mod<uint64_t> *mem = new simple_memory_mod<uint64_t>("mem", memory, MEM_SIZE);

    // matrix multiplier (top-level)
    mat_mult_ga *matrix_multiplier = new mat_mult_ga("matrix_multiplier",
                                                    n_clusters,
                                                    n_cores_per_cluster,
                                                    kernel_dim,
                                                    payload_packet_size,
                                                    n_groups_per_cluster);
    matrix_multiplier->mem_if(*mem);

    // initialize clusters and cores
    cluster *clusters[n_clusters];
    core *cores[n_clusters * n_cores_per_cluster];
    cluster_memory *cluster_mems[n_clusters * (n_cores_per_cluster - 1)];

    // dummy components
    cluster *dummy_cluster = new cluster("dummy_cluster", 0, 0, 0, 0, 0);
    core *dummy_core = new core("dummy_core");
    for (int i = 0; i < MAX_N_CORES_PER_CLUSTER; i++) {
        dummy_cluster->core_ifs[i](*dummy_core);
    }
    cluster_memory *dummy_cluster_mem = new cluster_memory("dummy_cluster_mem", 0);
    for (int i = 0; i < MAX_N_CORES_PER_CLUSTER-1; i++) {
        dummy_cluster->subres_mem_ifs[i](*dummy_cluster_mem);
    }

    // initialize each cluster
    int i = 0;
    for (i = 0; i < n_clusters; i++) {
        // initialize each cluster
        clusters[i] = new cluster(("cluster" + std::to_string(i)).c_str(),
                                    i*n_groups_per_cluster, // start group offset
                                    n_groups_per_cluster,   // number of groups to process
                                    n_cores_per_cluster,    // number of cores
                                    kernel_dim,             // dimension of the kernel
                                    payload_packet_size     // number of bytes in each packet
                                    );

        // initialize each core for each cluster
        int j = 0;
        for (; j < n_cores_per_cluster; j++) {
            cores[j + i * n_cores_per_cluster] = new core(("cluster" + std::to_string(i) + "core" + std::to_string(j)).c_str());
            clusters[i]->core_ifs[j](*cores[j + i * n_cores_per_cluster]);
        }
        // garbage cores
        for (; j < MAX_N_CORES_PER_CLUSTER; j++) {
            clusters[i]->core_ifs[j](*dummy_core);
        }

        // initialize each memory for each cluster
        for (j = 0; j < n_cores_per_cluster-1; j++) {
            cluster_mems[j + i * (n_cores_per_cluster - 1)] = new cluster_memory(("cluster" + std::to_string(i) + "mem" + std::to_string(j)).c_str(), n_groups_per_cluster);
            clusters[i]->subres_mem_ifs[j](*cluster_mems[j + i * (n_cores_per_cluster - 1)]);
        }
        // garbage memories
        for (; j < MAX_N_CORES_PER_CLUSTER-1; j++) {
            clusters[i]->subres_mem_ifs[j](*dummy_cluster_mem);
        }

        // connect each cluster to the matrix multiplier (top-level)
        matrix_multiplier->cluster_ifs[i](*clusters[i]);
    }
    // garbage clusters
    for (; i < MAX_N_CLUSTERS; i++) {
        matrix_multiplier->cluster_ifs[i](*dummy_cluster);
    }

    // command issuer (CPU)
    mat_mult_cmd *cpu = new mat_mult_cmd("cpu", memory, kernel_dim, true);
    cpu->mm_if(*matrix_multiplier);

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
    sc_tracer::close();

    // print report
    // for (i = 0; i < n_clusters * (n_cores_per_cluster - 1); i++) {
        // std::cout << i << " " << cluster_mems[i]->_name << std::endl;
        // cluster_mems[i]->print_report();
    // }

    return 0;
}
