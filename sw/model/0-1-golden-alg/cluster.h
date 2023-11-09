
#include "systemc.h"
#include "system.h"
#include "core.h"

#ifndef CLUSTER_H
#define CLUSTER_H

#define INTERNAL_MEMORY_SIZE MAT_COLS*(MAX_KERN_DIM-1)

class cluster_if : virtual public sc_interface {

    public:

        /** Constructor. */
        cluster_if(uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint32_t packet_size);

        /** Once the command header has been received, activate the cluster. */
        virtual void activate(uint32_t command_type, uint32_t r, uint32_t c) = 0;

        /** Disable the kernel after all payload packets received. */
        virtual void disable() = 0;

        /** Receive data to process (kernel values or input image data). */
        virtual void receiveData(uint64_t addr, uint8_t* data, uint8_t *out_ptr) = 0;

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

class cluster : public sc_module, public cluster_if {

    public:

        // internal core interfaces
        sc_port<core_if> core_ifs[MAX_N_CORES_PER_CLUSTER];

        /** Constructor. */
        cluster(sc_module_name name, uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint8_t kernel_dim, uint32_t packet_size);

        /** Once the command header has been received, activate the cluster. */
        void activate(uint32_t command_type, uint32_t r, uint32_t c);

        /** Disable the kernel after all payload packets received. */
        void disable();

        /** Receive data to process (kernel values or input image data). */
        void receiveData(uint64_t addr, uint8_t* data, uint8_t *out_ptr);

        /** Reset the cluster. */
        void reset();

    private:

        // internal memories
        uint8_t _kernel_mem[KERN_SIZE_ROUNDED];
        uint8_t _subres_mem[INTERNAL_MEMORY_SIZE];

        uint8_t _kern_dim;

        // per-image configuration
        bool     _enabled;
        uint32_t _command_type;
        uint32_t _max_r;
        uint32_t _max_c;

        // FSM
        uint32_t _counter;
        uint32_t _col_i; // Ccrrent local column being processed

};

#endif // CLUSTER_H
