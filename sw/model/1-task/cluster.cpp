
#include "cluster.h"
#include "system.h"
#include "systemc.h"
#include "mat_mult_if.h"
#include "core.h"

#include <iostream>

cluster_memory::cluster_memory(sc_module_name name, bool dummy)
    : memory_if<uint32_t, uint32_t>(name, INTERNAL_MEMORY_SIZE_PER_GROUP), sc_module(name), _mem(nullptr), _r_cursor(0), _w_cursor(0)
{
    if (!dummy) {
        _mem = new uint32_t[INTERNAL_MEMORY_SIZE_PER_GROUP];
        memset(_mem, 0, INTERNAL_MEMORY_SIZE_PER_GROUP * sizeof(uint32_t));
    }
}

cluster_memory::~cluster_memory() {
    if (_mem) {
        delete _mem;
    }
}

bool cluster_memory::do_read(uint32_t addr, uint32_t& data) {
    data = _mem[_r_cursor++]; // get current sub result for update
    DEBUGF("[%s] loaded subresult (%d/%d) %08x", this->name(), _r_cursor, INTERNAL_MEMORY_SIZE_PER_GROUP, data);
    _r_cursor %= INTERNAL_MEMORY_SIZE_PER_GROUP; // wrap cursor
    return true;
}

bool cluster_memory::do_write(uint32_t addr, uint32_t data) {
    _mem[_w_cursor++] = data; // store sub result and increment cursor
    DEBUGF("[%s] stored subresult (%d/%d) %08x", this->name(), _w_cursor, INTERNAL_MEMORY_SIZE_PER_GROUP, data);
    _w_cursor %= INTERNAL_MEMORY_SIZE_PER_GROUP; // wrap cursor
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
    : sc_module(name), cluster_if(start_group, n_groups, n_cores, packet_size), _kern_dim(kernel_dim),
    _enabled("enabled"), _command_type("command_type"), _res_valid("res_valid"), _new_packet("new_packet")
{
    if (n_groups) {
        _out = new uint8_t[n_groups];
    }

    _enabled.write(SC_LOGIC_0);
    _res_valid.write(SC_LOGIC_0);
    _new_packet.write(SC_LOGIC_0);

    SC_THREAD(main);
}

cluster::~cluster() {
    if (_n_groups) {
        delete _out;
    }
}

void cluster::activate(uint32_t command_type, uint32_t r, uint32_t c) {
    LOGF("[%s] configured for cmd type %d, %dx%d matrix", this->name(), command_type, r, c);
    // allow cluster to tap the bus data
    _enabled.write(SC_LOGIC_1);

    // latch configuration
    _command_type.write(command_type);

    // initialize FSM
    _kernel_cursor = 0;
}

void cluster::disable() {
    // _enabled = false;
    _enabled.write(SC_LOGIC_0);
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
    if ((addr & ADDR_MASK) >= OFFSET_PAYLOAD && _enabled.read().to_bool()) {
        if (_command_type == MM_CMD_KERN) {
            *((uint64_t*)(_kernel_mem + _kernel_cursor)) = packet;
            _kernel_cursor += PACKET_BYTES;
        }
        else if (_command_type == MM_CMD_SUBJ) {
            *(uint64_t*)(_dispatch_data + (_kern_dim - 1)) = packet;
        }

        _new_packet.write(SC_LOGIC_1);

        DEBUGF("[%s] Recv %016lx", this->name(), packet);
    }
}

void cluster::clear_packet() {
    _new_packet.write(SC_LOGIC_0);
}

bool cluster::get_results(uint8_t *res) {
    memcpy(res, _out, _n_groups);
    if (_res_valid.read().to_bool()) {
        DEBUGF("[%s] Returning group %d: %02x to %016lx", this->name(), _start_group, _out[0], (uint64_t)(void*)res);
    }
    else {
        DEBUGF("[%s] no results", this->name());
    }
    return _res_valid.read().to_bool();
}

/**
  * @brief  Cluster FSM reset.
  */
void cluster::reset() {
    _new_packet.write(SC_LOGIC_0);
}

void cluster::main() {
    // local copies for processing
    uint32_t command_type;
    uint8_t dispatch_data[MAX_CLUSTER_INPUT_SIZE];

    // local variables
    int group_i;
    int core_i;
    int row_i;
    uint32_t subres;

    while (true) {
        // capture values on posedge
        command_type = _command_type.read();
        YIELD();

        // compute and update
        if (_enabled.read().to_bool()) {
            // route previous output data
            _res_valid.write(SC_LOGIC_0);
            for (group_i = 0; group_i < _n_groups; group_i++) {
                // iterate through kernel rows (start with last to not overwrite subresults)
                core_i = _n_cores-1;
                for (row_i = _kern_dim-1; row_i >= 0; --row_i){
                    // output result from previous computation
                    if (core_ifs[core_i]->get_row_result(subres)) {
                        if (row_i == (_kern_dim - 1)) {
                            // output total result
                            _out[group_i] = (uint8_t)subres; // implicit mask with 0xff
                            _res_valid.write(SC_LOGIC_1);

                            DEBUGF("[%score%d] (row %d) result %08x", this->name(), core_i, row_i, subres);
                        }
                        else {
                            // write subresult to internal memory
                            subres_mem_ifs[row_i]->write(0, subres);
                        }
                    }

                    // move to next core
                    if (!core_i) core_i = _n_cores;
                    core_i--;
                }
            }

            // route input data
            if (_new_packet.read().to_bool()) {
                memcpy(dispatch_data, _dispatch_data, MAX_CLUSTER_INPUT_SIZE);

                if (command_type == MM_CMD_SUBJ) {
                    for (group_i = 0; group_i < _n_groups; group_i++) {
                        // iterate through kernel rows (start with last to not overwrite subresults)
                        core_i = _n_cores-1;
                        for (row_i = _kern_dim-1; row_i >= 0; --row_i){
                            // load previous sub result to accumulate (only after first row)
                            if(row_i != 0) {
                                subres_mem_ifs[row_i-1]->read(0, subres);
                            }
                            else {
                                subres = 0;
                                // LOGF("[%score%d] (row %d) loaded subresult %08x", this->name(), core_i, row_i, subres);
                            }

                            // send current kernel row and data group to core to calculate
                            core_ifs[core_i]->calculate_row_result(subres, _kernel_mem + (row_i * _kern_dim), dispatch_data + _start_group + group_i);

                            // move to next core
                            if (!core_i) core_i = _n_cores;
                            core_i--;
                        }
                    }
                }

                // buffer current (kernel_dim - 1) last pixels
                DEBUGF("[%s] data: %02x %02x %02x %02x %02x", this->name(),
                    _dispatch_data[_start_group+0], _dispatch_data[_start_group+1], _dispatch_data[_start_group+2], _dispatch_data[_start_group+3], _dispatch_data[_start_group+4]);
                memcpy(_dispatch_data, dispatch_data + _packet_size, (_kern_dim - 1));
                DEBUGF("[%s] shifted data: %02x %02x %02x %02x %02x", this->name(),
                    _dispatch_data[_start_group+0], _dispatch_data[_start_group+1], _dispatch_data[_start_group+2], _dispatch_data[_start_group+3], _dispatch_data[_start_group+4]);
            }
            else {
                for (core_i = 0; core_i < _n_cores; ++core_i) {
                    core_ifs[core_i]->reset();
                }
            }
        }
        else {
            _res_valid.write(SC_LOGIC_0);
            for (core_i = 0; core_i < _n_cores; ++core_i) {
                core_ifs[core_i]->reset();
            }
        }

        // next posedge
        POS_CORE();
    }
}
