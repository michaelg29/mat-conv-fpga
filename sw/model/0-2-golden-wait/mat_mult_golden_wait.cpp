
#include "mat_mult_golden_wait.h"
#include "system.h"
#include "systemc.h"


#include <iostream>
#include <string>

mat_mult_wait::mat_mult_wait(sc_module_name name, uint8_t *ext_mem)
    : mat_mult(name, ext_mem)
{
    _mmu = new mmu("mmu");
}

/**
 * Receive a 64-bit packet. If there is an error in the current packet,
 * latch the status in the acknowledge packet.
 */
bool mat_mult_wait::receive64bitPacket(uint64_t addr, uint64_t packet) {

    if (_cur_state == WAIT_DATA && GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
        _cur_state = PROCESSING;
        _mmu->setProcessingState();  
    }   

    if (_cur_state == WAIT_DATA) {
        sendBytes(addr, packet);        
    }
    else if(_cur_state ==  PROCESSING){
        sendBytes(addr, packet);
        computeBytes();
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
        _mmu->store((uint8_t)((packet>>i)&0xFF));
    }
}

void mat_mult_wait::computeBytes(){

    for (int i = 0; i < PACKET_BYTES; ++i) {
        _mmu->compute_output();
    }
}