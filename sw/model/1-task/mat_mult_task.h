
#include "systemc.h"
#include "system.h"
#include "mat_mult_if.h"
#include "mat_mult_top.h"
#include "cluster.h"

#ifndef MAT_MULT_TASK_H
#define MAT_MULT_TASK_H

#define IN_FIFO_BUF_N_BITS 4
#define IN_FIFO_BUF_SIZE (1 << IN_FIFO_BUF_N_BITS)
#define IN_FIFO_PTR_MASK (IN_FIFO_BUF_SIZE - 1)

/**
 * @brief Task-level implementation of matrix convolution using the designed algorithm.
 */
class mat_mult_task : public mat_mult_top {

    public:

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
        SC_HAS_PROCESS(mat_mult_task);
        mat_mult_task(sc_module_name name,
                    uint32_t n_clusters = MAX_N_CLUSTERS,
                    uint32_t n_cores_per_cluster = MAX_N_CORES_PER_CLUSTER,
                    uint8_t kern_dim = MAX_KERN_DIM,
                    uint32_t packet_size = PACKET_BYTES,
                    uint32_t n_groups_per_cluster = PACKET_BYTES/MAX_N_CLUSTERS);

    private:

        /** Configuration. */
        uint8_t _kern_dim;
        uint8_t _hf_kern_dim;
        uint32_t _packet_size;
        uint32_t _n_groups_per_cluster;
        uint32_t _n_cores_per_cluster;
        uint32_t _n_clusters;

        /** Input FSM. */
        uint64_t *_cur_ptr;
        uint32_t _expected_el;
        uint32_t _loaded_el;

        /** Output FSM. */
        uint64_t _out_addr;
        uint32_t _out_row;
        uint32_t _out_col;

        /** Input signals. */
        sc_signal<sc_logic> _new_packet;
        sc_signal<uint64_t> _addr;
        sc_signal<uint64_t> _packet;

        /** Input packet FIFO buffers. */
        int32_t _in_fifo_head;
        int32_t _in_fifo_tail;
        uint64_t _in_fifo_packet[IN_FIFO_BUF_SIZE];
        uint64_t _in_fifo_addr[IN_FIFO_BUF_SIZE];

        /** Output buffers. */
        uint8_t _results[PACKET_BYTES * 2]; // store the output pixels from the current batch (has a size of _packet_size)

        /** mat_mult_top.receive_packet */
        bool receive_packet(uint64_t addr, uint64_t packet);
        void protected_reset();

        /** Dispatch a 64-bit packet to the internal FSM and clusters. */
        void dispatch_packet(uint64_t addr, uint64_t packet);

        /** Write the results to the command host. */
        void write_results_buffer();

        /** Complete payload reception if the module received all packets. */
        void check_complete_reception();

        /** Main thread function. */
        void main();

};

#endif // MAT_MULT_TASK_H
