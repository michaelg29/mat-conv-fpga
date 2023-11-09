
#include "mat_mult_golden_alg.h"
#include "system.h"
#include "systemc.h"

#include <iostream>
#include <string>

mat_mult_ga::mat_mult_ga(sc_module_name name, uint32_t n_clusters, uint32_t n_cores_per_cluster, uint8_t kern_dim, uint32_t packet_size, uint32_t n_groups_per_cluster)
    : mat_mult(name), _n_clusters(n_clusters), _n_cores_per_cluster(n_cores_per_cluster), _kern_dim(kern_dim), _hf_kern_dim(kern_dim >> 1), _packet_size(packet_size), _n_groups_per_cluster(n_groups_per_cluster)
{

}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult_ga::receive64bitPacket(uint64_t addr, uint64_t packet) {
    //TODO current code assumes that the packets received are immediately distributed to clusters instead of buffered
    //and concatenated with other packets. Might want to add support for this (another optimization parameter).
    //Partially fixed

    // stitch incoming packet to buffered (kernel_dim - 1) pixels from previous dispatch
    *((uint64_t*)(_cluster_dispatch_data + (_kern_dim - 1))) = packet;

    if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ){
        // dispatch input iamge data to clusters
        for (int i = 0; i < _n_clusters; i++) {
            dispatchCluster(i, addr, _cluster_dispatch_data);
        }

        // buffer current (kernel_dim - 1) last pixels
        memcpy(_cluster_dispatch_data, _cluster_dispatch_data + _packet_size, (_kern_dim - 1));

        // store output pixels
        if (_cur_state == PROCESSING && _out_row >= 0) {
            write_results_buffer();
        }
    }
    else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN){
        // dispatch kernel values to clusters
        for (int i = 0; i < _n_clusters; i++) {
            dispatchCluster(i, addr, _cluster_dispatch_data);
        }
    }

    // address check
    if ((addr & ADDR_MASK) >= (OFFSET_PAYLOAD)) {
        // increment counters
        _loaded_el += PACKET_BYTES;
        _out_col += PACKET_BYTES;
        if (_out_col + PACKET_BYTES == (uint32_t)GET_CMD_SIZE_COLS(_cur_cmd)) {
            // if last column, write last packet with padding
            write_results_buffer();

            // new row
            _out_row++;
            _out_col = -(int32_t)PACKET_BYTES;

            // TODO: write last rows as zeros
        }

        // transition FSM
        if (_loaded_el >= _expected_el) {
            std::cout << "Received all payload" << std::endl;
            complete_payload();
            for (int i = 0; i < _n_clusters; ++i) {
                cluster_ifs[i]->disable();
            }
        }
        return true;
    }

    // internal FSM to decode command
    if (!mat_mult::receive64bitPacket(addr, packet)) return false;

    // activate clusters if necessary
    if (_cur_state == WAIT_DATA) {
        cout << "ACTIVATE CLUSTERS" << endl;
        for (int i = 0; i < _n_clusters; ++i) {
            cluster_ifs[i]->activate(GET_CMD_TYPE(_cur_cmd), GET_CMD_SIZE_ROWS(_cur_cmd), GET_CMD_SIZE_COLS(_cur_cmd));
        }
        _loaded_el = 0;
        _out_row = -_hf_kern_dim;
        _out_col = -(int32_t)PACKET_BYTES;
        _cur_state = PROCESSING;
        _out_addr = (uint64_t)GET_CMD_OUT_ADDR(_cur_cmd);
    }

    return true;
}

void mat_mult_ga::dispatchCluster(int i, uint64_t addr, uint8_t* cluster_data) {
    //cluster_ifs[i]->receiveData(addr, cluster_data, _results + (i * _n_groups_per_cluster));
    cluster_ifs[i]->receiveData(addr, cluster_data, _results + (PACKET_BYTES - _hf_kern_dim) + (i * _n_groups_per_cluster));
}

void mat_mult_ga::protected_reset() {
    for (int i = 0; i < _n_clusters; ++i) {
        cluster_ifs[i]->reset();
    }

    mat_mult::protected_reset();
}

void mat_mult_ga::write_results_buffer() {
    // get data from buffer
    _out_data = *(uint64_t*)_results;

    // mask output to remove border elements
    _out_mask = 0xffffffffffffffff;
    if (_out_row < _hf_kern_dim || _out_row >= (uint32_t)GET_CMD_SIZE_ROWS(_cur_cmd) - _hf_kern_dim) {
        _out_mask = 0x0;
    }
    if (_out_col < _hf_kern_dim) {
        _out_mask &= 0xffffffffffffffff << (_hf_kern_dim * 8);
    }
    if (_out_col + PACKET_BYTES >= (uint32_t)GET_CMD_SIZE_COLS(_cur_cmd) - _hf_kern_dim) {
        _out_mask &= 0xffffffffffffffff >> (_hf_kern_dim * 8);
    }

    // write data with mask
    if (_out_col >= 0 && _out_row >= 0) {
        mem_if->write(_out_addr, _out_data & _out_mask);
        _out_addr += PACKET_BYTES;
    }

    // shift
    memcpy(_results, _results + PACKET_BYTES, PACKET_BYTES);
}
