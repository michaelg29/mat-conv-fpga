
#include "systemc.h"
#include <string>

#ifndef M_FIFO_H
#define M_FIFO_H

template <typename T, unsigned int ADDR_SIZE>
class FIFO_ASYNC_RTL : public sc_module {
 
    public:
        sc_in<sc_logic> rclk, wclk;
        sc_in<sc_logic> ren, wen;
        sc_in<T> dataIn;
        sc_out<T> dataOut;
        sc_out<sc_logic> rvalid, wvalid;
        
        unsigned int wptr = 0;
        unsigned int rptr = 0;
        
        unsigned int wrap_mask = 1 << ADDR_SIZE;
        unsigned int addr_mask = (1 << ADDR_SIZE) - 1;

        T mem[1 << ADDR_SIZE];
        
        SC_HAS_PROCESS(FIFO_ASYNC_RTL);
        
        FIFO_ASYNC_RTL(sc_module_name name);
        
    private:
        bool is_full();
        bool is_empty();
    
        void p_read();
        void p_write();

};

#endif
