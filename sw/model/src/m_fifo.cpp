
#include "m_fifo.h"

template <typename T, unsigned int ADDR_SIZE>
FIFO_ASYNC_RTL<T, ADDR_SIZE>::FIFO_ASYNC_RTL(sc_module_name name) : sc_module(name) {
    SC_METHOD(p_read);
    sensitive << rclk.pos();
    
    SC_METHOD(p_write);
    sensitive << wclk.pos();
}

template <typename T, unsigned int ADDR_SIZE>
bool FIFO_ASYNC_RTL<T, ADDR_SIZE>::is_full() {
    return (wptr & addr_mask == rptr & addr_mask) && (wptr & wrap_mask != rptr & wrap_mask);
}

template <typename T, unsigned int ADDR_SIZE>
bool FIFO_ASYNC_RTL<T, ADDR_SIZE>::is_empty() {
    return (wptr & addr_mask == rptr & addr_mask) && (wptr & wrap_mask == rptr & wrap_mask);
}

template <typename T, unsigned int ADDR_SIZE>
void FIFO_ASYNC_RTL<T, ADDR_SIZE>::p_read() {
    if (ren.read().to_bool() && !is_empty()) {
        dataOut.write(mem[rptr]);
        rptr++;
        rvalid.write(SC_LOGIC_1);
    }
    else {
        rvalid.write(SC_LOGIC_0);
    }
}

template <typename T, unsigned int ADDR_SIZE>
void FIFO_ASYNC_RTL<T, ADDR_SIZE>::p_write() {
    if (wen.read().to_bool() && !is_full()) {
        mem[wptr] = dataIn.read();
        wptr++;
        wvalid.write(SC_LOGIC_1);
    }
    else {
        wvalid.write(SC_LOGIC_0);
    }
}
