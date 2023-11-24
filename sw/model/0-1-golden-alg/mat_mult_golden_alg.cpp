
#include "mat_mult_golden_alg.h"
#include "system.h"
#include "systemc.h"

#include <iostream>
#include <string>

mat_mult_ga::mat_mult_ga(sc_module_name name, uint32_t n_clusters, uint32_t n_cores_per_cluster, uint8_t kern_dim, uint32_t packet_size, uint32_t n_groups_per_cluster)
    : mat_mult_top(name), _n_clusters(n_clusters), _n_cores_per_cluster(n_cores_per_cluster), _kern_dim(kern_dim), _hf_kern_dim(kern_dim >> 1), _packet_size(packet_size), _n_groups_per_cluster(n_groups_per_cluster)
{

}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult_ga::receive_packet(uint64_t addr, uint64_t packet) {
    //TODO current code assumes that the packets received are immediately distributed to clusters instead of buffered
    //and concatenated with other packets. Might want to add support for this (another optimization parameter).
    //Partially fixed

    // stitch incoming packet to buffered (kernel_dim - 1) pixels from previous dispatch
    //*((uint64_t*)(_cluster_dispatch_data + (_kern_dim - 1))) = packet;

    if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ){
        // dispatch input image data to clusters
        for (int i = 0; i < _n_clusters; i++) {
            //cluster_ifs[i]->receive_data(addr, _cluster_dispatch_data, _results + (PACKET_BYTES - _hf_kern_dim) + (i * _n_groups_per_cluster));
            cluster_ifs[i]->receive_packet(addr, packet, _results + (PACKET_BYTES - _hf_kern_dim) + (i * _n_groups_per_cluster));
        }

        // buffer current (kernel_dim - 1) last pixels
        //memcpy(_cluster_dispatch_data, _cluster_dispatch_data + _packet_size, (_kern_dim - 1));

        // store output pixels
        if (_cur_state == WAIT_DATA && _out_row >= 0) {
            write_results_buffer();
        }
    }
    else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
        // dispatch kernel values to clusters
        for (int i = 0; i < _n_clusters; i++) {
            //cluster_ifs[i]->receive_data(addr, _cluster_dispatch_data, _results + (PACKET_BYTES - _hf_kern_dim) + (i * _n_groups_per_cluster));
            cluster_ifs[i]->receive_packet(addr, packet, _results + (PACKET_BYTES - _hf_kern_dim) + (i * _n_groups_per_cluster));
        }
    }

    // address check
    if ((addr & ADDR_MASK) >= (OFFSET_PAYLOAD)) {
        // increment counters
        _regs.status_reg.ready = false;
        _loaded_el += PACKET_BYTES;
        if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
            _out_col += PACKET_BYTES;
            if (_out_col + PACKET_BYTES == (uint32_t)GET_CMD_SIZE_COLS(_cur_cmd)) {
                // if last column, write last complete packet
                // TODO: do computation for final elements without new packet
                write_results_buffer();

                // new row
                _out_row++;
                _out_col = -(int32_t)PACKET_BYTES;
            }
        }

        // complete payload reception
        if (_loaded_el >= _expected_el) {
            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                // write last rows as zeros
                for (; _out_addr < _max_out_addr; _out_addr += PACKET_BYTES) {
                    
                    mem_if->write(_out_addr, 0);
                }
            }

            std::cout << "Received all payload " << _loaded_el << " " << _expected_el << std::endl;
            _loaded_el = 0;
            _expected_el = 0;
            _regs.status_reg.ready = true;
            for (int i = 0; i < _n_clusters; ++i) {
                cluster_ifs[i]->disable();
            }
        }
    }
    else {
        // write data in packet to destination
        *_cur_ptr = packet;

        // calculate expected elements
        if (_cur_state == WAIT_CMD_SIZE) {
            _expected_el = (uint16_t)(GET_CMD_SIZE_ROWS(_cur_cmd)) * (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
        }
    }

    // decoding FSM
    calculate_next_state();

    // advance pointer
    _cur_ptr += 1;
    if (_next_state == WAIT_CMD_KERN_SKEY || _next_state == WAIT_CMD_SUBJ_SKEY) {
        // reset for new command
        _cur_ptr = (uint64_t*)&_cur_cmd.s_key;
    }

    // activate clusters if necessary
    if (_cur_state != WAIT_DATA && _next_state == WAIT_DATA) {
        cout << "ACTIVATE CLUSTERS" << endl;
        for (int i = 0; i < _n_clusters; ++i) {
            cluster_ifs[i]->activate(GET_CMD_TYPE(_cur_cmd), GET_CMD_SIZE_ROWS(_cur_cmd), GET_CMD_SIZE_COLS(_cur_cmd));
        }
        _loaded_el = 0;
        _out_row = -_hf_kern_dim;
        _out_col = -(int32_t)PACKET_BYTES;
        _out_addr = (uint64_t)GET_CMD_OUT_ADDR(_cur_cmd);
        _max_out_addr = _out_addr + GET_CMD_SIZE_ROWS(_cur_cmd) * GET_CMD_SIZE_COLS(_cur_cmd);
    }

    // advance to next state
    advance_state();
    
    wait(1, SC_NS);

    return true;
}

void mat_mult_ga::protected_reset() {
    // reset internal clusters
    for (int i = 0; i < _n_clusters; ++i) {
        cluster_ifs[i]->reset();
    }

    // reset state
    _cur_ptr = (uint64_t*)&_cur_cmd.s_key;
    _loaded_el = 0;
    _expected_el = 0;

    // reset registers
    _regs.status_reg.ready = true;
    _regs.status_reg.error = MM_STAT_OKAY;

    // superclass reset
    mat_mult_top::protected_reset();
}

void mat_mult_ga::write_results_buffer() {
    // get data from buffer
    _out_data = *(uint64_t*)_results;

    // write data with mask
    if (_out_col >= 0 && _out_row >= 0) {
        //printf("%016lx, %016lx\n", _out_data, _out_addr);
        mem_if->write(_out_addr, _out_data);
        _out_addr += PACKET_BYTES;
        //exit(0);
    }

    // shift
    memcpy(_results, _results + PACKET_BYTES, PACKET_BYTES);
}
