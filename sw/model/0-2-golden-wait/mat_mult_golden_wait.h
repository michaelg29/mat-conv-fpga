
#include "systemc.h"
#include "system.h"
#include "../0-appl/mat_mult.h"
#include "mmu.h"
#include "concat.h"

#ifndef MAT_MULT_WAIT_H
#define MAT_MULT_WAIT_H

#define MAX_N_CLUSTERS 8
#define PACKET_BYTES 64 / 8

class mat_mult_wait: public mat_mult {
    
    public:
    
        SC_HAS_PROCESS(mat_mult_wait);
    
        mat_mult_wait(sc_module_name name, uint8_t *ext_mem);

    private:

        mmu* _mmu;

        concat* _concat;

        uint64_t _out_reg;

        uint64_t _out_addr=0;

        uint32_t _kernel_size, _row_length;


        bool receive64bitPacket(uint64_t addr, uint64_t packet);
        void protected_reset();
        void sendBytes(uint64_t addr, uint64_t packet);
        void computeBytes(); 

};

#endif // MAT_MULT_WAIT_H
