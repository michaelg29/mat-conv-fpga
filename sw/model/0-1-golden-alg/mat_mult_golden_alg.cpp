
#include "mat_mult_golden_alg.h"
#include "system.h"
#include "systemc.h"

#include <iostream>
#include <string>

mat_mult_ga::mat_mult_ga(sc_module_name name, uint8_t *ext_mem, uint32_t n_clusters, uint32_t n_cores_per_cluster)
    : mat_mult(name, ext_mem), _n_clusters(n_clusters)
{
    for (int i = 0; i < PACKET_BYTES; ++i) {
        _k_list[i] = i;
    }
    
    for (int i = 0; i < _n_clusters; ++i) {
        // initialize each cluster
        _clusters[i] = new cluster(("cluster" + std::to_string(i)).c_str(),
            _k_list + i, 1, // pointer to assigned values of k, number of assigned values
            n_cores_per_cluster); // number of cores
    }
}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult_ga::receive64bitPacket(uint64_t addr, uint64_t packet) {
    // dispatch data to clusters
    for (int i = 0; i < _n_clusters; ++i) {
        dispatchCluster(i, addr, packet);
    }
    
    // address check
    if ((addr & ADDR_MASK) >= (OFFSET_PAYLOAD)) {
        _loaded_el += 8;
        if (_loaded_el >= _expected_el) {
            complete_payload();
            for (int i = 0; i < _n_clusters; ++i) {
                _clusters[i]->reset();
            }
        }
        return true;
    }
    
    // internal FSM
    if (!mat_mult::receive64bitPacket(addr, packet)) return false;
    
    // activate clusters if necessary
    if (_cur_state == WAIT_DATA) {
        for (int i = 0; i < _n_clusters; ++i) {
            _clusters[i]->activate(GET_CMD_TYPE(_cur_cmd), GET_CMD_SIZE_ROWS(_cur_cmd), GET_CMD_SIZE_COLS(_cur_cmd));
        }
        _loaded_el = 0;
        _cur_state = PROCESSING;
        sc_stop();
    }
    
    return true;
}

void mat_mult_ga::dispatchCluster(int i, uint64_t addr, uint64_t packet) {
    _clusters[i]->receive64bitPacket(addr, packet);
}

void mat_mult_ga::protected_reset() {
    for (int i = 0; i < _n_clusters; ++i) {
        _clusters[i]->reset();
    }
    
    mat_mult::protected_reset();
}
