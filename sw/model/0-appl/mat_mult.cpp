
#include "mat_mult.h"
#include "system.h"
#include "systemc.h"
#include <stdio.h>

mat_mult::mat_mult(sc_module_name name, uint8_t *ext_mem)
    : mat_mult_if(ext_mem), sc_module(name)
{

}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult::receive64bitPacket(uint64_t addr, uint64_t packet) {
    if (_cur_state == PROCESSING) {
        return false;
    }
    
    // write data in packet to destination
    *_cur_ptr = packet;

    // state transition
    switch (_cur_state) {
        case WAIT_CMD_KERN_SKEY:
        {
            _cur_ack.status = MM_STAT_OKAY;

            if (_cur_cmd.s_key != MM_S_KEY) _cur_ack.status |= MM_STAT_ERR_KEY;

            if (GET_CMD_TYPE(_cur_cmd) != MM_CMD_KERN) _cur_ack.status |= MM_STAT_ERR_ORD;

            // latch in acknowledge message
            _cur_ack.s_key = MM_S_KEY;
            _cur_ack.command = _cur_cmd.command;

            // advance pointer and state
            _cur_ptr = (uint64_t*)&_cur_cmd.size;
            _cur_state = WAIT_CMD_SIZE;
            std::cout << "WAIT_CMD_KERN_SKEY " << _cur_ack.status << std::endl;
            break;
        }
        case WAIT_CMD_SUBJ_SKEY:
        {
            _cur_ack.status = MM_STAT_OKAY;

            if (_cur_cmd.s_key != MM_S_KEY) _cur_ack.status |= MM_STAT_ERR_KEY;

            if ((GET_CMD_TYPE(_cur_cmd)) != (MM_CMD_SUBJ)) _cur_ack.status |= MM_STAT_ERR_ORD;

            // latch in acknowledge message
            _cur_ack.s_key = MM_S_KEY;
            _cur_ack.command = _cur_cmd.command;

            // advance pointer and state
            _cur_ptr = (uint64_t*)&_cur_cmd.size;
            _cur_state = WAIT_CMD_SIZE;
            std::cout << "WAIT_CMD_SUBJ_SKEY " << _cur_ack.status << std::endl;
            break;
        }
        case WAIT_CMD_SIZE:
        {
            uint16_t rows = (uint16_t)(GET_CMD_SIZE_ROWS(_cur_cmd));
            uint16_t cols = (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
            _expected_el = rows * cols;
            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN &&
                ((rows != cols) ||
                ((rows & 0b1) == 0) ||
                (rows > 5)))
                _cur_ack.status |= MM_STAT_ERR_SIZE;

            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ &&
                (cols & 0b111) != 0)
                _cur_ack.status |= MM_STAT_ERR_SIZE;
                
            std::cout << rows << "x" << cols << std::endl;

            // latch in acknowledge message
            _cur_ack.size = _cur_cmd.size;
            _cur_ack.tx_addr = _cur_cmd.tx_addr;

            // advance pointer and state
            _cur_ptr = (uint64_t*)&_cur_cmd.trans_id;
            _cur_state = WAIT_CMD_TID;
            std::cout << "WAIT_CMD_SIZE " << _cur_ack.status << std::endl;
            break;
        }
        case WAIT_CMD_TID:
        {
            // latch in acknowledge message
            _cur_ack.trans_id = _cur_cmd.trans_id;

            // advance pointer and state
            _cur_ptr = (uint64_t*)&_cur_cmd.reserved;
            _cur_state = WAIT_CMD_EKEY;
            std::cout << "WAIT_CMD_TID " << _cur_ack.status << std::endl;
            break;
        }
        case WAIT_CMD_EKEY:
        {
            if (((uint32_t)_cur_cmd.chksum) != ((uint32_t)CALC_CMD_CHKSUM(_cur_cmd))) _cur_ack.status |= MM_STAT_ERR_CHKSM;
            
            // latch in acknowledge message
            _cur_ack.e_key = MM_E_KEY;
            _cur_ack.chksum = (uint32_t)CALC_ACK_CHKSUM(_cur_ack);

            _loaded_el = 0;

            // write ack packet to CPU
            _cur_ptr = (uint64_t*)&_cur_ack;
            for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
                memIf->write(_cur_cmd.tx_addr, *_cur_ptr);
                
                // advance cursors
                _cur_cmd.tx_addr += 8;
                _cur_ptr += 1;
            }
            
            // raise interrupt

            if (_cur_ack.status == MM_STAT_OKAY) {
                // advance pointer
                if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
                    _cur_ptr = (uint64_t*)kern_mem;
                }
                else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                    _cur_ptr = (uint64_t*)subj_mem;
                }
                
                // advance state
                _cur_state = WAIT_DATA;
            }
            else {
                // advance pointer
                _cur_ptr = (uint64_t*)&_cur_cmd;
                
                // advance state
                if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
                    _cur_state = WAIT_CMD_KERN_SKEY;
                }
                else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                    _cur_state = WAIT_CMD_SUBJ_SKEY;
                }
            }
            
            std::cout << "WAIT_CMD_EKEY " << _cur_ack.status << std::endl;

            break;
        }
        case WAIT_DATA:
        {
            _loaded_el += 8;
            _cur_ptr += 1;
            
            // advance state if all elements loaded
            if (_loaded_el >= _expected_el) {
                if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                    _cur_state = PROCESSING;
                    calculate();
                }
                
                complete_payload();
            }
            
            //std::cout << "WAIT_DATA " << _cur_ack.status << std::endl;
            break;
        }
        default:
        {
            return false;
            break;
        }
    };

    return true;
}

void mat_mult::protected_reset() {
    _cur_ptr = (uint64_t*)&_cur_cmd.s_key;
}

void mat_mult::complete_payload() {
    _cur_ptr = (uint64_t*)&_cur_cmd;
    if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
        _cur_state = WAIT_CMD_SUBJ_SKEY;
    }
    else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
        _cur_state = WAIT_CMD_KERN_SKEY;
    }
}

void mat_mult::calculate() {
    // bounds
    uint16_t rows = (uint16_t)(GET_CMD_SIZE_ROWS(_cur_cmd));
    uint16_t cols = (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
    uint16_t hf_kernel_size = (uint16_t)MAX_KERN_ROWS >> 1;
    
    // calculations
    uint64_t data = 0;
    uint64_t addr = ((uint64_t)GET_CMD_OUT_ADDR(_cur_cmd)) << 3;
    std::cout << "Writing to " << addr << ", matrix is " << rows << "x" << cols << std::endl;
    for (uint16_t r = 0; r < rows; r++) {
        for (uint16_t c = 0; c < cols; c++) {
            // accumulate result
            int32_t res = 0;
            
            // compute kernel dot product with neighborhood
            if (r >= hf_kernel_size && r < (rows-hf_kernel_size) && c >= hf_kernel_size && c < (cols-hf_kernel_size)) {
                int kerneli = 0;
                for (int i = -hf_kernel_size; i <= hf_kernel_size; i++) {
                    for (int j = -hf_kernel_size; j <= hf_kernel_size; j++) {
                        res += (int32_t)(uint32_t)subj_mem[(r+i)*cols + (c+j)] // matrix value is unsigned byte
                             * (int32_t)(int8_t)kern_mem[kerneli]; // kernel value is signed byte
                        kerneli++;
                    }
                }
            }
            
            // write data to output buffer
            data |= (uint64_t)(res & 0xff) << ((c & 0x7) << 3);
            //printf("%02x => %016lx\n", res & 0xff, data);
            
            // write data back to CPU memory
            if ((c & 0x7) == 0x7) {
                memIf->write(addr, data);
                //printf("Write to %016lx, %016lx\n", addr, data);
                data = 0;
                addr += 8;
            }
        }
    }
    
    std::cout << "Done multiplying" << std::endl;
    
    //_cur_state = WAIT_CMD_KERN_SKEY;
}
