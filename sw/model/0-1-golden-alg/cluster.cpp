
#include "cluster.h"
#include "system.h"
#include "systemc.h"
#include "mat_mult_if.h"
#include "core.h"

#include <iostream>

cluster::cluster(sc_module_name name, uint32_t *k, uint32_t n_k, uint32_t n_cores)
    : sc_module(name), _k(k), _n_k(n_k), _n_cores(n_cores)
{
    // initialize internal cores
    for (int i = 0; i < _n_cores; ++i) {
        _cores[i] = new core(("cluster" + std::to_string(k[0]) + "core" + std::to_string(i)).c_str());
    }
}

void cluster::activate(uint32_t command_type, uint32_t r, uint32_t c) {
    std::cout << "Configured " << command_type << " " << r << " " << c << std::endl;
    // allow cluster to tap the bus data
    _enabled = true;
    
    // latch configuration
    _command_type = command_type;
    _max_r = r;
    _max_c = c;
    
    // initialize FSM
    _counter = 0;
}

void cluster::receive64bitPacket(uint64_t addr, uint64_t packet) {
    // ensure enabled
    if (!_enabled) return;

    // activate for address
    if ((addr & ADDR_MASK) < OFFSET_PAYLOAD) return;
    
    if (_command_type == MM_CMD_KERN) {
        // store kernel data
        *(uint64_t*)(_kernel_mem + _counter) = packet;
    }
    else if (_command_type == MM_CMD_SUBJ) {
        // insert new element into 12-element subject buffer to be processed
        *(uint64_t*)(_packet_buf + 4) = packet;

        int core_i = 0;
        // iterate through data groups
        for (int i = 0; i < _n_k; ++i) {
            // iterate through kernel rows
            for (int j = 0; j < MAX_KERN_ROWS; ++j) {
                // send current kernel row and data group to core to calculate
                _cores[core_i]->calculate_row_result(_kernel_mem + j * MAX_KERN_ROWS, _packet_buf + _k[i]);
                
                // move to next core
                core_i = (core_i + 1) % _n_cores;
            }
        }

        // buffer last four elements for the next packet
        *(uint32_t*)(_packet_buf) = ((uint32_t*)(_packet_buf + 8))[0];
    }

    // update state
    _counter += sizeof(uint64_t);
}

void cluster::reset() {
    _enabled = false;
}
