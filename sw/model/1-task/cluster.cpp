
#include "cluster.h"
#include "system.h"
#include "systemc.h"
#include "mat_mult_if.h"
#include "core.h"

#include <iostream>

cluster_memory::cluster_memory(sc_module_name name, bool dummy)
    : memory_if<uint32_t, uint32_t>(name, INTERNAL_MEMORY_SIZE_PER_GROUP), sc_module(name), _cursor(0)
{
    if (!dummy) {
        _mem = new uint32_t[INTERNAL_MEMORY_SIZE_PER_GROUP];
        memset(_mem, 0, INTERNAL_MEMORY_SIZE_PER_GROUP * sizeof(uint32_t));
    }
}

bool cluster_memory::do_read(uint32_t addr, uint32_t& data) {
    data = _mem[_cursor]; // get current sub result for update
    return true;
}

bool cluster_memory::do_write(uint32_t addr, uint32_t data) {
    _mem[_cursor++] = data; // store sub result and increment cursor
    _cursor %= INTERNAL_MEMORY_SIZE_PER_GROUP; // wrap cursor
    return true;
}

cluster_if::cluster_if(uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint32_t packet_size)
    : _start_group(start_group), _n_groups(n_groups), _n_cores(n_cores), _packet_size(packet_size)
{

}


/**
  * @brief  Cluster constructor function.
  *
  * @param  name        Give a name to the cluster.
  * @param  start_group Offset to the first group to process in the input data.
  * @param  n_groups    Number of groups of input data to process.
  * @param  n_cores     Number of computation cores in the cluster.
  * @param  kernel_dim  Size of the current kernel.
  */
cluster::cluster(sc_module_name name, uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint8_t kernel_dim, uint32_t packet_size)
    : sc_module(name), cluster_if(start_group, n_groups, n_cores, packet_size), _kern_dim(kernel_dim)
{
    if (n_groups) {
        _out = new uint8_t[n_groups];
    }

    SC_THREAD(main);
}

void cluster::activate(uint32_t command_type, uint32_t r, uint32_t c) {
    std::cout << "Configured " << command_type << " " << r << " " << c << std::endl;
    // allow cluster to tap the bus data
    _enabled = true;

    // latch configuration
    _command_type = command_type;

    // initialize FSM
    if (command_type == MM_CMD_KERN) {
        _packet_dst = (uint64_t*)_kernel_mem;
    }
    else if (command_type == MM_CMD_SUBJ) {
        // stitch incoming packets to buffered (kernel_dim - 1) pixels from previous dispatch
        _packet_dst = (uint64_t*)(_dispatch_data + (_kern_dim - 1));
    }
}

void cluster::disable() {
    _enabled = false;
}

/**
  * @brief  Cluster reception of data and processing.
  * @note   Receives the kernel values and the input pixels. Will only respond to address TODO.
  *         The cluster must be enabled before this function can be used.
  *
  * @param  addr        Address of the command received
  * @param  packet      The received packet
  * @param  out_ptr     Address to store the local output pixels.
  */
void cluster::receive_packet(uint64_t addr, uint64_t packet, uint8_t *out_ptr) {
    // address check
    if ((addr & ADDR_MASK) >= OFFSET_PAYLOAD) {
        // log request
        _new_packet = true;
        _packet = packet;
    }
}

bool cluster::get_results(uint8_t *res) {
    memcpy(res, _out, _n_groups);
    return _res_valid;
}

/**
  * @brief  Cluster FSM reset.
  */
void cluster::reset() {
    _res_valid = false;
    _new_packet = false;

    for (int i = 0; i < MAX_N_CORES_PER_CLUSTER; ++i) {
        core_ifs[i]->reset();
    }
}

void cluster::main() {
    // local copies for processing
    bool enabled;
    bool new_packet;
    uint32_t command_type;
    uint64_t packet;
    uint64_t *packet_dst;

    // local variables
    int group_i;
    int core_i;
    int row_i;
    uint32_t subres;

    while (true) {
        // capture values on posedge
        enabled = _enabled;
        new_packet = _new_packet;
        command_type = _command_type;
        packet = _packet;
        packet_dst = _packet_dst;
        YIELD();

        // compute and update
        _res_valid = false;

        if (enabled) {
            // route previous output data
            for (group_i = 0; group_i < _n_groups; group_i++) {
                // iterate through kernel rows (start with last to not overwrite subresults)
                core_i = 0;
                for (row_i = _kern_dim-1; row_i >= 0; --row_i){
                    // output result from previous computation
                    if (core_ifs[core_i]->get_row_result(subres)) {
                        LOGF("[%s] core %d (row %d) produced subres %08x", this->name(), core_i, row_i, subres);
                        if (row_i == (_kern_dim - 1)) {
                            // output total result
                            _out[group_i] = (uint8_t)subres; // implicit mask with 0xff
                            _res_valid = true;
                        }
                        else {
                            // write subresult to internal memory
                            subres_mem_ifs[row_i]->write(0, subres);
                        }
                    }

                    // move to next core
                    core_i = (core_i + 1) % _n_cores;
                }
            }

            // route input data
            if (new_packet) {
                *packet_dst = packet;

                if (command_type == MM_CMD_KERN) {
                    // increment kernel cursor
                    _packet_dst = packet_dst + 1;
                }
                else if (command_type == MM_CMD_SUBJ) {
                    // iterate through data groups
                    for (group_i = 0; group_i < _n_groups; group_i++) {
                        // iterate through kernel rows (start with last to not overwrite subresults)
                        core_i = 0;
                        for (row_i = _kern_dim-1; row_i >= 0; --row_i){
                            // load previous sub result to accumulate (only after first row)
                            if(row_i != 0) {
                                subres_mem_ifs[row_i-1]->read(0, subres);
                            }

                            // send current kernel row and data group to core to calculate
                            core_ifs[core_i]->calculate_row_result(subres, _kernel_mem + (row_i * _kern_dim), _dispatch_data + _start_group + group_i);

                            // move to next core
                            core_i = (core_i + 1) % _n_cores;
                        }
                    }

                    // buffer current (kernel_dim - 1) last pixels
                    memcpy(_dispatch_data, _dispatch_data + _packet_size, (_kern_dim - 1));
                }

                _new_packet = false;
            }
        }

        // next posedge
        POS_CORE();
    }
}
