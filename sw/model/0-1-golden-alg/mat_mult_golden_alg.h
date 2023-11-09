
#include "systemc.h"
#include "system.h"
#include "../0-appl/mat_mult.h"
#include "cluster.h"

#ifndef MAT_MULT_GA_H
#define MAT_MULT_GA_H

class mat_mult_ga : public mat_mult {

    public:

        SC_HAS_PROCESS(mat_mult_ga);

        // internal clusters
        sc_port<cluster_if> cluster_ifs[MAX_N_CLUSTERS];

        mat_mult_ga(sc_module_name name,
                    uint32_t n_clusters = MAX_N_CLUSTERS,
                    uint32_t n_cores_per_cluster = MAX_N_CORES_PER_CLUSTER,
                    uint8_t kern_dim = MAX_KERN_DIM,
                    uint32_t packet_size = PACKET_BYTES,
                    uint32_t n_groups_per_cluster = PACKET_BYTES/MAX_N_CLUSTERS);

    private:

        // cluster dispatch handling
        uint8_t _cluster_dispatch_data[(MAX_KERN_DIM - 1) + PACKET_BYTES];

        // configuration
        uint8_t _kern_dim;
        uint8_t _hf_kern_dim;
        uint32_t _packet_size;
        uint32_t _n_groups_per_cluster;
        uint32_t _n_cores_per_cluster;

        // counters

        // output data
        uint64_t _out_addr;
        int32_t _out_row;
        int32_t _out_col;
        uint64_t _out_data;
        uint64_t _out_mask;

        // internal clusters
        uint32_t _n_clusters = 0;
        uint8_t _results[PACKET_BYTES * 2]; // store the output pixels from the current batch (has a size of _packet_size)

        bool receive64bitPacket(uint64_t addr, uint64_t packet);
        void dispatchCluster(int i, uint64_t addr, uint8_t* cluster_data);
        void protected_reset();
        void write_results_buffer();

        void calculate();

};

#endif // MAT_MULT_GA_H
