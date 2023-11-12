
#include "systemc.h"
#include "system.h"


#ifndef CONCAT_H
#define CONCAT_H

#define PACKET_BYTES 64 / 8




class concat : public sc_module {

    public:

        concat(sc_module_name name, uint64_t* reg_out_ptr);

        uint64_t* reg_out;

        void concatenate();
        
        uint32_t inputReg=0;



    private:
            
        uint8_t _concat_counter;
        uint64_t _concatenateReg=0;

        
};

#endif // MMU_H
