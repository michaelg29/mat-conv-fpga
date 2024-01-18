
#include "mat_mult.h"
#include "system.h"
#include "systemc.h"
#include <stdio.h>

mat_mult::mat_mult(sc_module_name name)
    : mat_mult_top(name), _loaded_el(0), _expected_el(0)
{

}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult::receive_packet(uint64_t addr, uint64_t packet) {
    // write data in packet to destination
    *_cur_ptr = packet;

    // preprocessing
    switch (_cur_state) {
    case WAIT_CMD_SIZE:
        // calculate expected elements
        if (_regs.cmd_type_reg.is_kern) {
            _expected_el = (uint32_t)(GET_CMD_SIZE_NELS(_cur_cmd));
            _kern_dim = GET_CMD_SIZE_ROWS(_cur_cmd);
            _hf_kern_dim = _kern_dim >> 1;
        }
        else if (_regs.cmd_type_reg.is_subj) {
            _expected_el = (uint32_t)(GET_CMD_SIZE_SUBJ_NELS(_cur_cmd));
        }
        
        LOGF("[%s] Expected elements %d", this->name(), _expected_el);
        break;

    case WAIT_DATA:
        _regs.status_reg.ready = false;
        _loaded_el += sizeof(uint64_t);
        
        // complete payload reception
        if (_loaded_el >= _expected_el) {
            LOGF("Loaded %d/%d", _loaded_el, _expected_el);
            // start calculating when all elements loaded
            if (_regs.cmd_type_reg.is_subj) {
                calculate();
            }
            _loaded_el = 0;
            _expected_el = 0;

            _regs.status_reg.ready = true;
            
            // issue acknowledge packet
            write_ack();
        }
        break;

    default:
        break;
    };

    // decoding FSM
    calculate_next_state();

    // advance pointer
    _cur_ptr += 1;
    if (_next_state == WAIT_CMD_SKEY) {
        // reset for new command
        _cur_ptr = (uint64_t*)&_cur_cmd.s_key;
    }
    else if (_cur_state != WAIT_DATA && _next_state == WAIT_DATA) {
        // point to internal memory
        if (_regs.cmd_type_reg.is_kern) {
            _cur_ptr = (uint64_t*)kern_mem;
        }
        else if (_regs.cmd_type_reg.is_subj) {
            _cur_ptr = (uint64_t*)subj_mem;
        }
    }

    // advance to next state
    advance_state();

    return true;
}

void mat_mult::protected_reset() {
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

void mat_mult::calculate() {
    // bounds
    uint16_t rows = (uint16_t)(GET_CMD_SIZE_SUBJ_ROWS(_cur_cmd));
    uint16_t cols = (uint16_t)(GET_CMD_SIZE_SUBJ_COLS(_cur_cmd));

    // calculations
    uint64_t data = 0;
    uint64_t addr = ((uint64_t)GET_CMD_OUT_ADDR(_cur_cmd));
    LOGF("[%s] writing to %016lx, matrix is %dx%d", this->name(), addr, rows, cols);
    for (uint16_t r = 0; r < rows; r++) {
        for (uint16_t c = 0; c < cols; c++) {
            // accumulate result
            uint32_t res = 0;

            // compute kernel dot product with neighborhood
            int kerneli = 0;
            for (int i = r - _hf_kern_dim; i <= r + _hf_kern_dim; i++) {
                for (int j = c - _hf_kern_dim; j <= c + _hf_kern_dim; j++) {
                    if (i >= 0 && i < rows && j >= 0 && j < cols) {
                        res += (uint32_t)subj_mem[i*cols + j] // matrix value is unsigned byte
                            * (uint32_t)kern_mem[kerneli]; // kernel value is signed byte
                    }
                    kerneli++;
                }
            }

            // write data to output buffer
            data |= (uint64_t)(res & 0xff) << ((c & 0x7) << 3);

            // write data back to CPU memory
            if ((c & 0x7) == 0x7) {
                mem_if->write(addr, data);
                //printf("Write to %016lx, %016lx\n", addr, data);
                data = 0;
                addr += 8;
            }
        }
    }

    LOGF("[%s] Done multiplying", this->name());
}
