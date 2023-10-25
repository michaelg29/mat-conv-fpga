
#include "cluster.h"
#include "system.h"
#include "systemc.h"
#include "mat_mult_if.h"
#include "core.h"

#include <iostream>

cluster_if::cluster_if(uint32_t *k, uint32_t n_k, uint32_t n_cores)
    : _k(k), _n_k(n_k), _n_cores(n_cores)
{

}

cluster::cluster(sc_module_name name, uint32_t *k, uint32_t n_k, uint32_t n_cores)
    : sc_module(name), cluster_if(k, n_k, n_cores)
{

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

void cluster::receive64bitPacket(uint64_t addr, uint64_t packet, uint8_t *out_ptr) {
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
        for (int p = 0; p < _n_k; ++p) {
            // iterate through kernel rows
            bool last_row = true;
            for (int n = MAX_KERN_ROWS-1; n >= 0; n--) {
                // get previous subresult
                uint32_t addr = 0; // TODO calculate address
                uint32_t subres = _subres_mem[addr];

                // send current kernel row and data group to core to calculate
                subres = core_ifs[core_i]->calculate_row_result(subres, _kernel_mem + n * MAX_KERN_ROWS, _packet_buf + _k[p]);

                if (last_row) {
                    // output result
                    last_row = false;
                    out_ptr[p] = (uint8_t)subres;
                }
                else {
                    // write subresult to internal memory
                    _subres_mem[addr] = subres;
                }

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
