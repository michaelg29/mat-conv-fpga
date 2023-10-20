
#include "cluster.h"
#include "system.h"
#include "systemc.h"
#include "mat_mult_if.h"
#include "core.h"

#include <iostream>

cluster::cluster(sc_module_name name, uint32_t *k, uint32_t n_k, uint32_t n_cores)
    : sc_module(name), _k(k), _n_k(n_k), _n_cores(n_cores)
{
    for (int i = 0; i < _n_cores; ++i) {
        _cores[i] = new core(("cluster" + std::to_string(k[0]) + "core" + std::to_string(i)).c_str());
    }
}

void cluster::configure(uint32_t status, uint32_t r, uint32_t c) {
    _enabled = status == MM_STAT_OKAY;
    _max_r = r;
    _max_c = c;
}

void cluster::receive64bitPacket(uint64_t addr, uint64_t packet) {
    // ensure enabled
    if (!_enabled) return;

    // activate for address
    if ((addr & ADDR_MASK) < OFFSET_PAYLOAD) return;

    // insert new element into 12-element buffer
    *(uint64_t*)(_packet_buf + 4) = packet;

    // dispatch packet to cores

    // update state
    _counter += 8;

    // buffer last four elements for the next packet
    *(uint32_t*)(_packet_buf) = ((uint32_t*)(_packet_buf + 8))[0];
}

void cluster::reset() {
    
}
