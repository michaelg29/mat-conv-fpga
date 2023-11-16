
#include "cluster.h"
#include "system.h"
#include "systemc.h"
#include "mat_mult_if.h"
#include "core.h"

#include <iostream>

cluster_memory::cluster_memory(sc_module_name name, uint32_t n_groups)
    : memory_if<uint32_t, uint32_t>(name, n_groups * INTERNAL_MEMORY_SIZE_PER_GROUP), sc_module(name), _n_groups(n_groups)
{
    if (n_groups) {
        _mem = (uint32_t*)malloc(n_groups * INTERNAL_MEMORY_SIZE_PER_GROUP * sizeof(uint32_t));
    }
}

bool cluster_memory::do_read(uint32_t addr, uint32_t& data) {
    data = _mem[addr];
    return true;
}

bool cluster_memory::do_write(uint32_t addr, uint32_t data) {
    _mem[addr] = data;
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
    _col_i = 0;
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
  * @param  data        Pointer to the received data
  * @param  out_ptr     Address to store the local output pixels.
  */
void cluster::receive_data(uint64_t addr, uint8_t* data, uint8_t *out_ptr) {

    // ensure enabled
    if (!_enabled) {
        return;
    }

    // activate for address
    if ((addr & ADDR_MASK) < OFFSET_PAYLOAD) {
        return;
    }

    if (_command_type == MM_CMD_KERN) {
        // store kernel data
        *(uint64_t*)(_kernel_mem + _counter) = *(uint64_t*)(data + (_kern_dim - 1)); // payload stored after the buffered bits
        _counter += PACKET_BYTES;
    }
    else if (_command_type == MM_CMD_SUBJ) {

        // iterate through data groups
        for (int group_i = 0; group_i < _n_groups; group_i++) {

            // iterate through kernel rows (start with last to not overwrite subresults)
            int core_i = 0;
            for(int row_i = _n_cores-1; row_i >= 0; --row_i){

                // load previous sub result to accumulate (only after first row)
                uint32_t subres = 0;
                if(row_i != 0) {
                    subres_mem_ifs[row_i-1]->read(_col_i, subres);
                }

                // send current kernel row and data group to core to calculate
                subres = core_ifs[core_i]->calculate_row_result(subres, _kernel_mem + (row_i * _kern_dim), _kern_dim, data + _start_group + group_i);

                if (row_i == (_kern_dim - 1)) {
                    // output total result
                    out_ptr[group_i] = (uint8_t)subres;
                }
                else {
                    // write subresult to internal memory
                    subres_mem_ifs[row_i]->write(_col_i, subres);
                }

                // move to next core
                core_i = (core_i + 1) % _n_cores;
            }

            // update current column id
            _col_i += 1;
        }

        // update state
        _counter += _packet_size;

        // update column id if end of row reached (_counter is a multiple of the packet size)
        if ((_counter % MAT_COLS) == 0){
            _col_i = 0;
        }
    }
}

/**
  * @brief  Cluster FSM reset.
  */
void cluster::reset() {
    _enabled = false;
}
