#include "concat.h"


concat::concat(sc_module_name name, uint64_t* reg_out_ptr):sc_module(name)
{
    _concat_counter = 0;
    reg_out = reg_out_ptr;
}

void concat::concatenate() {

    _concatenateReg &= ~(((uint64_t)0xff) << (_concat_counter << 3));
    
    //round by adding .5 and truncate
    _concatenateReg |= ((((uint64_t)(inputReg+(1<<6))>>7)&0xff) << (_concat_counter << 3));//todo check for fixedpoitn number & stuff. divide by 273 only for testing purposes of gaussian 5x5

    if(_concat_counter >= PACKET_BYTES-1) {
        //write reg to memory bus
        *reg_out = _concatenateReg;
        _concat_counter = 0;
    }
    else {
        _concat_counter = _concat_counter + 1;
    }
}
