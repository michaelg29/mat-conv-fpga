
#include "mat_mult.h"
#include "system.h"
#include "systemc.h"
#include <stdio.h>

mat_mult::mat_mult(sc_module_name name, uint8_t *ext_mem)
    : mat_mult_if(name, ext_mem)
{

}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult::transmit64bitPacket(uint64_t addr, uint64_t packet) {
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
            _cur_ack.trans_id = _cur_ack.trans_id;

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
                if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
                    _cur_state = WAIT_CMD_SUBJ_SKEY;
                    _cur_ptr = (uint64_t*)&_cur_cmd;
                }
                else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                    _cur_state = PROCESSING;
                    _cur_ptr = (uint64_t*)&_cur_cmd;
                    
                    std::cout << std::endl << "==========" << std::endl;
                    std::cout << "Input matrix:" << std::endl;
                    printMat(subj_mem, MAT_COLS, 0, 0, 0, 10, 10);
                    
                    std::cout << "Kernel:" << std::endl;
                    printMat(kern_mem, MAX_KERN_ROWS, 0, 0, 0, MAX_KERN_ROWS, MAX_KERN_ROWS);
                }
            }
            
            //std::cout << "WAIT_DATA " << _cur_ack.status << std::endl;
            break;
        }
        case PROCESSING:
        {
            return false;
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
