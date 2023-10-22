
#include "systemc.h"
#include "system.h"
#include "core.h"

#ifndef CLUSTER_H
#define CLUSTER_H

#define INTERNAL_MEMORY_SIZE 1 << 6

#define MAX_N_CORES 5

class cluster : public sc_module {

    public:

        /** Constructor. */
        cluster(sc_module_name name, uint32_t *k, uint32_t n_k, uint32_t n_cores);

        /** Once the command header has been received, activate the cluster. */
        void activate(uint32_t command_type, uint32_t r, uint32_t c);

        /** Receive a 64 bit packet. */
        void receive64bitPacket(uint64_t addr, uint64_t packet);
        
        /** Reset the cluster. */
        void reset();

    private:
    
        // internal cores
        uint32_t _n_cores;
        core *_cores[MAX_N_CORES];

        // internal memories
        uint8_t _kernel_mem[KERN_SIZE_ROUNDED];
        uint8_t _subres_mem[INTERNAL_MEMORY_SIZE];
        uint8_t _packet_buf[12];

        // one-time configuration
        uint32_t *_k; // assigned group values
        uint32_t _n_k; // number of assigned groups

        // per-image configuration
        bool     _enabled;
        uint32_t _command_type;
        uint32_t _max_r;
        uint32_t _max_c;
        
        // FSM
        uint32_t _counter;

};

#endif // CLUSTER_H
