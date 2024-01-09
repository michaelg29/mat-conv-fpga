
#include "system.h"
#include "memory_if.hpp"
#include "cluster_if.h"
#include "core.h"

#include "systemc.h"

#ifndef CLUSTER_H
#define CLUSTER_H

/**
 * @brief Memory to store sub results in a cluster.
 */
typedef memory_if<uint32_t, uint32_t> cluster_memory_if_t;
class cluster_memory : public sc_module, public cluster_memory_if_t {

    public:

        cluster_memory(sc_module_name name, bool dummy=true);

        bool do_read(uint32_t addr, uint32_t& data);

        bool do_write(uint32_t addr, uint32_t data);

    private:

        /** Number of groups for which the memory will hold sub results. */
        uint32_t _n_groups;

        /** Memory array. */
        uint32_t *_mem;

        /** Current cursor. */
        uint32_t _cursor;

};

/**
 * @brief Golden model implementation of a cluster.
 */
class cluster : public sc_module, public cluster_if {

    public:

        // internal core interfaces
        sc_port<core_if> core_ifs[MAX_N_CORES_PER_CLUSTER];

        // internal memory interface
        sc_port<cluster_memory_if_t> subres_mem_ifs[MAX_KERN_DIM-1];

        /** Constructor. */
        cluster(sc_module_name name, uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint8_t kernel_dim, uint32_t packet_size);

        /** Once the command header has been received, activate the cluster. */
        void activate(uint32_t command_type, uint32_t r, uint32_t c);

        /** Disable the kernel after all payload packets received. */
        void disable();

        /** Receive data to process (kernel values or input image data). */
        void receive_packet(uint64_t addr, uint64_t packet, uint8_t *out_ptr);

        /** Not used in this implementation. */
        bool get_results(uint8_t *res);

        /** Reset the cluster. */
        void reset();

    private:

        // dispatch data
        uint8_t _dispatch_data[MAX_CLUSTER_INPUT_SIZE];

        // internal kernel storage as registers
        uint8_t _kernel_mem[KERN_SIZE_ROUNDED];
        uint8_t _kern_dim;

        // per-image configuration
        bool     _enabled;
        uint32_t _command_type;

        // FSM
        uint64_t *_packet_dst; // where to route packet data

};

#endif // CLUSTER_H
