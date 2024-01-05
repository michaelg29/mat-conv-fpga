
#include "mat_mult_golden_wait.h"
#include "system.h"
#include "systemc.h"


#include <iostream>
#include <string>

mat_mult_wait::mat_mult_wait(sc_module_name name)
    : mat_mult(name)
{
    _concat = new concat("concatenator", &_out_reg);
    _mmu = new mmu("mmu", &(_concat->inputReg));
}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult_wait::receive_packet(uint64_t addr, uint64_t packet) {
    // address check
    if ((addr & ADDR_MASK) >= (OFFSET_PAYLOAD)) {
        if (_cur_state ==  WAIT_DATA){
            _regs.status_reg.ready = false;

            sendBytes(addr, packet);

            _loaded_el+=8;

            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                computeBytes(); // computes 8 output

                //if check address to start writing outputs
                if(_loaded_el > (_kernel_size*(1+_row_length>>1)-1)){
                    uint64_t out_addr = (uint64_t)GET_CMD_OUT_ADDR(_cur_cmd);
                    mem_if->write((((uint64_t)GET_CMD_OUT_ADDR(_cur_cmd))) + _out_addr, _out_reg);
                    _out_addr += 8;
                }

                //finish last rows after receiving the last packet. ugly but good enough for now
                if (_loaded_el >= _expected_el) {
                   while (_out_addr<_expected_el) {
                        sendBytes(addr, 0);
                        computeBytes();
                        uint64_t out_addr = (uint64_t)GET_CMD_OUT_ADDR(_cur_cmd);
                        mem_if->write((((uint64_t)GET_CMD_OUT_ADDR(_cur_cmd))) + _out_addr, _out_reg);
                        _out_addr += 8;
                   }
                }
            }

            // complete payload reception
            if (_loaded_el >= _expected_el) {
                _loaded_el = 0;
                _expected_el = 0;

                _regs.status_reg.ready = true;
                if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN)
                     _mmu->setProcessingState();

                // issue acknowledge packet
                write_ack();
            }
        }
    }
    else {
        // write data in packet to destination
        *_cur_ptr = packet;

        if(_cur_state == WAIT_CMD_SIZE)
        {
            _expected_el = (uint16_t)(GET_CMD_SIZE_ROWS(_cur_cmd)) * (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
            uint16_t cols = (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN){
                _kernel_size = cols;
                _mmu->setKernelSize(_kernel_size);
            }

            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ)
                _row_length = cols;
        }
    }

    // decoding FSM
    calculate_next_state();

    // advance pointer
    if (_cur_state != WAIT_DATA)
        _cur_ptr += 1;

    if (_next_state == WAIT_CMD_SKEY) {
        // reset for new command
        _cur_ptr = (uint64_t*)&_cur_cmd.s_key;
    }

    // advance to next state
    advance_state();

    wait(1, SC_NS);

    return true;
}


void mat_mult_wait::protected_reset() {
    _mmu->protected_reset();

    mat_mult::protected_reset();
}

void mat_mult_wait::sendBytes(uint64_t addr, uint64_t packet){

    for (int i = 0; i < PACKET_BYTES; ++i) {
        _mmu->store((uint8_t)((packet>>i*8)&0xFF));
    }
}

void mat_mult_wait::computeBytes(){

    for (int i = 0; i < PACKET_BYTES; ++i) {
        _mmu->compute_output();
        _concat->concatenate();
    }
}