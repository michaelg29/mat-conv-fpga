
#include "mat_mult_task.h"
#include "system.h"
#include "systemc.h"

#include <iostream>
#include <string>

mat_mult_task::mat_mult_task(sc_module_name name, uint32_t n_clusters, uint32_t n_cores_per_cluster, uint8_t kern_dim, uint32_t packet_size, uint32_t n_groups_per_cluster)
    : mat_mult_top(name), _n_clusters(n_clusters), _n_cores_per_cluster(n_cores_per_cluster), _kern_dim(kern_dim), _hf_kern_dim(kern_dim >> 1), _packet_size(packet_size), _n_groups_per_cluster(n_groups_per_cluster)
{
    SC_THREAD(main);
}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult_task::receive_packet(uint64_t addr, uint64_t packet) {
    _new_packet = true;
    _addr = addr;
    _packet = packet;

    // dispatch values to clusters
    for (int i = 0; i < _n_clusters; i++) {
        //cluster_ifs[i]->receive_packet(addr, packet, _results + (PACKET_BYTES - _hf_kern_dim) + (i * _n_groups_per_cluster));
        cluster_ifs[i]->receive_packet(addr, packet, nullptr);
    }
    _loaded_el += PACKET_BYTES;

    POS_CORE();

    if (_regs.cmd_type_reg.is_subj && _cur_state == WAIT_DATA) {
        if (_loaded_el && ((_loaded_el % (uint32_t)GET_CMD_SIZE_COLS(_cur_cmd)) == 0)) {
            _new_packet = true;
            _addr = addr;
            _packet = 0;

            for (int i = 0; i < _n_clusters; i++) {
                cluster_ifs[i]->receive_packet(addr, 0, nullptr);
            }

            POS_CORE();
        }
    }

    return true;
}

void mat_mult_task::protected_reset() {
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

void mat_mult_task::write_results_buffer() {
    // get data from buffer
    _out_data = *(uint64_t*)_results;

    // write data with mask
    if (_out_col >= 0 && _out_row >= 0) {
        LOGF("[%s] Writing %016lx to %016lx, ", this->name(), _out_data, _out_addr);
        mem_if->write(_out_addr, _out_data);
        _out_addr += PACKET_BYTES;
    }

    // shift
    memcpy(_results, _results + PACKET_BYTES, PACKET_BYTES);
}

void mat_mult_task::main() {
    // local copies of interface variables
    bool new_packet;
    uint64_t addr;
    uint64_t packet;

    // local variables
    int i;
    bool res_valid;
    uint8_t *out_ptr;

    while (true) {
        // capture values on posedge
        new_packet = _new_packet;
        addr = _addr;
        packet = _packet;
        YIELD();

        // =====================
        // ===== INPUT FSM =====
        // =====================
        if (new_packet) {
            // address check
            if ((addr & ADDR_MASK) >= (OFFSET_PAYLOAD)) {
                // increment counters
                //_loaded_el += PACKET_BYTES;
                _regs.status_reg.ready = false;
            }
            else {
                // write data in packet to destination
                *_cur_ptr = packet;

                // calculate expected elements
                if (_cur_state == WAIT_CMD_SIZE) {
                    _expected_el = (uint16_t)(GET_CMD_SIZE_ROWS(_cur_cmd)) * (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
                }
            }
        }

        // ======================
        // ===== OUTPUT FSM =====
        // ======================
        if (_cur_state == WAIT_DATA) {
            if (_regs.cmd_type_reg.is_kern) {
                if (_loaded_el >= _expected_el) {
                    LOGF("Received all payload %d/%d", _loaded_el, _expected_el);
                    _loaded_el = 0;
                    _expected_el = 0;
                    _regs.status_reg.ready = true;
                    for (i = 0; i < _n_clusters; ++i) {
                        cluster_ifs[i]->disable();
                    }

                    // issue acknowledge packet
                    write_ack();
                }
            }
            else if (_regs.cmd_type_reg.is_subj) {
                res_valid = false;
                out_ptr = _results + (PACKET_BYTES - _hf_kern_dim);
                for (i = 0; i < _n_clusters; ++i, out_ptr += _n_groups_per_cluster) {
                    if (cluster_ifs[i]->get_results(out_ptr)) {
                        //LOGF("[%s] Cluster %d cannot write.", this->name(), i);
                        res_valid = true;
                    }
                }

                if (res_valid) {
                    write_results_buffer();
                    LOGF("Written (%d/%d, %d)", _out_row, (int32_t)GET_CMD_SIZE_ROWS(_cur_cmd), _out_col);

                    _out_col += PACKET_BYTES;
                    if (_out_col > (uint32_t)GET_CMD_SIZE_COLS(_cur_cmd) - _hf_kern_dim) {
                        // new row
                        _out_row++;
                        _out_col = -(int32_t)PACKET_BYTES;
                    }

                    if (_out_row >= (int32_t)GET_CMD_SIZE_ROWS(_cur_cmd) - _hf_kern_dim) {
                        LOGF("Received and wrote all payload %d/%d", _loaded_el, _expected_el);
                        _loaded_el = 0;
                        _expected_el = 0;
                        _regs.status_reg.ready = true;
                        for (i = 0; i < _n_clusters; ++i) {
                            cluster_ifs[i]->disable();
                        }

                        // issue acknowledge packet
                        write_ack();
                    }
                }
                
                //LOGF("[%s]: writing to %016lx", this->name(), _out_addr);
                /*// store output pixels
                if (_cur_state == WAIT_DATA) {
                    write_results_buffer();
                }

                if (_regs.cmd_type_reg.is_subj) {
                    _out_col += PACKET_BYTES;
                    if (_out_col == (uint32_t)GET_CMD_SIZE_COLS(_cur_cmd)) {
                        // if last column, write last complete packet
                        for (int i = 0; i < _n_clusters; i++) {
                            cluster_ifs[i]->receive_packet(addr, 0, _results + (PACKET_BYTES - _hf_kern_dim) + (i * _n_groups_per_cluster));
                        }
                        write_results_buffer();

                        // new row
                        _out_row++;
                        _out_col = 0;
                    }
                }

                // complete payload reception
                if (_loaded_el >= _expected_el) {
                    LOGF("Received all payload %d/%d", _loaded_el, _expected_el);
                    _loaded_el = 0;
                    _expected_el = 0;
                    _regs.status_reg.ready = true;
                    for (int i = 0; i < _n_clusters; ++i) {
                        cluster_ifs[i]->disable();
                    }

                    // issue acknowledge packet
                    write_ack();
                }*/
            }
        }

        // determine next state
        if (new_packet || res_valid) {
            calculate_next_state();
        }

        // advance pointer
        _cur_ptr += 1;
        if (_next_state == WAIT_CMD_SKEY) {
            // reset for new command
            _cur_ptr = (uint64_t*)&_cur_cmd.s_key;
        }

        // activate clusters if necessary
        if (_cur_state != WAIT_DATA && _next_state == WAIT_DATA) {
            LOG("ACTIVATE CLUSTERS");
            for (int i = 0; i < _n_clusters; ++i) {
                cluster_ifs[i]->activate(GET_CMD_TYPE(_cur_cmd), GET_CMD_SIZE_ROWS(_cur_cmd), GET_CMD_SIZE_COLS(_cur_cmd));
            }
            _loaded_el = 0;
            _out_row = -_hf_kern_dim;
            _out_col = -(int32_t)PACKET_BYTES;
            _out_addr = (uint64_t)GET_CMD_OUT_ADDR(_cur_cmd);
        }

        _new_packet = false;

        // advance to next state
        advance_state();

        // next posedge
        POS_CORE();
    }
}
