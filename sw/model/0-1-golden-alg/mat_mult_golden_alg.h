
#include "systemc.h"
#include "system.h"
#include "../0-appl/mat_mult.h"
#include "cluster.h"

#ifndef MAT_MULT_GA_H
#define MAT_MULT_GA_H

#define MAX_N_CLUSTERS 8
#define PACKET_BYTES 64 / 8

class mat_mult_ga : public mat_mult {
    
    public:
    
        SC_HAS_PROCESS(mat_mult_ga);
        
        // internal clusters
        sc_port<cluster_if> cluster_ifs[MAX_N_CLUSTERS];
    
        mat_mult_ga(sc_module_name name, uint8_t *ext_mem, uint32_t n_clusters = MAX_N_CLUSTERS, uint32_t n_cores_per_cluster = MAX_N_CORES);

    private:
    
        uint32_t _k_list[PACKET_BYTES];
    
        // internal clusters
        uint32_t _n_clusters = 0;
        uint8_t _results[MAX_N_CLUSTERS];
    
        bool receive64bitPacket(uint64_t addr, uint64_t packet);
        void dispatchCluster(int i, uint64_t addr, uint64_t packet);
        void protected_reset();
        
        void calculate();

};

#endif // MAT_MULT_GA_H
