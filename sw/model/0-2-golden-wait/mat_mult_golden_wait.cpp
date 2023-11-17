
#include "mat_mult_golden_wait.h"
#include "system.h"
#include "systemc.h"


#include <iostream>
#include <string>

mat_mult_wait::mat_mult_wait(sc_module_name name, uint8_t *ext_mem)
    : mat_mult(name, ext_mem)
{
    _concat = new concat("concatenator", &_out_reg);
    _mmu = new mmu("mmu", &(_concat->inputReg));
}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult_wait::receive64bitPacket(uint64_t addr, uint64_t packet) {

    if(_cur_state== WAIT_CMD_SIZE)
    {
        *_cur_ptr = packet;
        uint16_t cols = (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
        if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN)
            _kernel_size = cols;

        if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ)
            _row_length = cols;            
    }


    if (_cur_state == WAIT_DATA && GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
        _cur_state = PROCESSING;
        _mmu->setProcessingState();  
    }   

    if (_cur_state == WAIT_DATA) {
        sendBytes(addr, packet);        
    }
    else if(_cur_state ==  PROCESSING){
        sendBytes(addr, packet);


        computeBytes();// computes 8 output
    
        
         
        _loaded_el+=8;
        //if check address
        if(_loaded_el >= (_kernel_size*(1+_row_length>>1)-1)){
            uint64_t out_addr = (uint64_t)GET_CMD_OUT_ADDR(_cur_cmd);
            mem_if->write((((uint64_t)GET_CMD_OUT_ADDR(_cur_cmd)) << 3) + _out_addr, _out_reg);
            _out_addr += 8;
        }

        //finish last rows after receiving the last packet. ugly but good enough for now
        if (_loaded_el >= _expected_el) {
           while (_out_addr<_expected_el) {
                computeBytes();
                uint64_t out_addr = (uint64_t)GET_CMD_OUT_ADDR(_cur_cmd);
                mem_if->write((((uint64_t)GET_CMD_OUT_ADDR(_cur_cmd)) << 3) + _out_addr, _out_reg);
                _out_addr += 8;
           }
        }
    }

    // internal FSM
    mat_mult::receive64bitPacket(addr, packet);    
   

   //_mmu->setProcessingState();
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