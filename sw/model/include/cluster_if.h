
#include "system.h"

#include "systemc.h"

#ifndef CLUSTER_IF_H
#define CLUSTER_IF_H

#define INTERNAL_MEMORY_SIZE_PER_GROUP MAT_COLS / MAX_N_CLUSTERS

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
        virtual void receive_packet(uint64_t addr, uint64_t packet, uint8_t *out_ptr) = 0;

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

#endif // CLUSTER_IF_H
