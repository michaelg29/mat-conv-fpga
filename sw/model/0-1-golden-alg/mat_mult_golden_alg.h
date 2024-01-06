
#include "systemc.h"
#include "system.h"
#include "mat_mult_if.h"
#include "cluster.h"

#ifndef MAT_MULT_GA_H
#define MAT_MULT_GA_H

/**
 * @brief Golden model implementation of matrix convolution using the 
          designed algorithm.
 */
class mat_mult_ga : public mat_mult_top {

    public:

        SC_HAS_PROCESS(mat_mult_ga);

        // internal clusters
        sc_port<cluster_if> cluster_ifs[MAX_N_CLUSTERS];

        /**
         * @brief Constructor with running parameters.
         * 
         * @param name                  SystemC module name
         * @param n_clusters            Number of clusters in the module.
         * @param n_cores_per_cluster   Number of cores in each cluster.
         * @param kern_dim              Kernel dimension.
         * @param packet_size           Number of pixels to be processed at once.
         * @param n_groups_per_cluster  Number of groups each cluster will calculate.
         */
        mat_mult_ga(sc_module_name name,
                    uint32_t n_clusters = MAX_N_CLUSTERS,
                    uint32_t n_cores_per_cluster = MAX_N_CORES_PER_CLUSTER,
                    uint8_t kern_dim = MAX_KERN_DIM,
                    uint32_t packet_size = PACKET_BYTES,
                    uint32_t n_groups_per_cluster = PACKET_BYTES/MAX_N_CLUSTERS);

    private:

        // cluster dispatch handling
        //uint8_t _cluster_dispatch_data[(MAX_KERN_DIM - 1) + PACKET_BYTES];

        // configuration
        uint8_t _kern_dim;
        uint8_t _hf_kern_dim;
        uint32_t _packet_size;
        uint32_t _n_groups_per_cluster;
        uint32_t _n_cores_per_cluster;

        // state variables
        uint64_t *_cur_ptr;
        uint32_t _expected_el;
        uint32_t _loaded_el;

        // counters
        uint64_t _out_addr;
        int32_t _out_row;
        int32_t _out_col;

        // output data
        uint64_t _out_data;

        // internal clusters
        uint32_t _n_clusters = 0;
        uint8_t _results[PACKET_BYTES * 2]; // store the output pixels from the current batch (has a size of _packet_size)

        bool receive_packet(uint64_t addr, uint64_t packet);
        void protected_reset();
        void write_results_buffer();

};

#endif // MAT_MULT_GA_H
