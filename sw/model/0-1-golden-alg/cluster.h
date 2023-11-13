
#include "system.h"
#include "memory_if.hpp"

#include "systemc.h"
#include "core.h"

#ifndef CLUSTER_H
#define CLUSTER_H

#define INTERNAL_MEMORY_SIZE_PER_GROUP MAT_COLS / MAX_N_CLUSTERS

/**
 * @brief Memory interface to store sub results in a cluster.
 */
typedef memory_if<uint32_t, uint32_t> cluster_memory_if_t;
class cluster_memory : public sc_module, public cluster_memory_if_t {

    public:

        cluster_memory(sc_module_name name, uint32_t n_groups);

        bool do_read(uint32_t addr, uint32_t& data);

        bool do_write(uint32_t addr, uint32_t data);

    private:

        // number of groups the memory will hold sub results for
        uint32_t _n_groups;

        // memory array
        uint32_t *_mem;

};

/**
 * @brief Interface to interact with an internal cluster.
 */
class cluster_if : virtual public sc_interface {

    public:

        /** Constructor. */
        cluster_if(uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint32_t packet_size);

        /** Once the command header has been received, activate the cluster. */
        virtual void activate(uint32_t command_type, uint32_t r, uint32_t c) = 0;

        /** Disable the kernel after all payload packets received. */
        virtual void disable() = 0;

        /** Receive data to process (kernel values or input image data). */
        virtual void receive_data(uint64_t addr, uint8_t* data, uint8_t *out_ptr) = 0;

        /** Reset the cluster. */
        virtual void reset() = 0;

    protected:

        // internal cores
        uint32_t _n_cores; // number of cores

        // one-time configuration
        uint32_t _start_group; // which group to start processing in the buffer
        uint32_t _n_groups; // number of groups to process in the buffer
        uint32_t _packet_size; // number of pixels in an input packet including buffered)

};

/**
 * @brief Golden model implementation of a cluster.
 */
class cluster : public sc_module, public cluster_if {

    public:

        // internal core interfaces
        sc_port<core_if> core_ifs[MAX_N_CORES_PER_CLUSTER];

        // internal memory interface
        sc_port<cluster_memory_if_t> subres_mem_ifs[MAX_N_CORES_PER_CLUSTER-1];

        /** Constructor. */
        cluster(sc_module_name name, uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint8_t kernel_dim, uint32_t packet_size);

        /** Once the command header has been received, activate the cluster. */
        void activate(uint32_t command_type, uint32_t r, uint32_t c);

        /** Disable the kernel after all payload packets received. */
        void disable();

        /** Receive data to process (kernel values or input image data). */
        void receive_data(uint64_t addr, uint8_t* data, uint8_t *out_ptr);

        /** Reset the cluster. */
        void reset();

    private:

        // internal kernel storage as registers
        uint8_t _kernel_mem[KERN_SIZE_ROUNDED];
        uint8_t _kern_dim;

        // per-image configuration
        bool     _enabled;
        uint32_t _command_type;
        uint32_t _max_r;
        uint32_t _max_c;

        // counters
        uint32_t _counter; // global image column counter
        uint32_t _col_i;   // current local column being processed

};

#endif // CLUSTER_H
