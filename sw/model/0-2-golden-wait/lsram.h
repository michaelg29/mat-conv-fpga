
#include "systemc.h"
#include "system.h"

#ifndef LSRAM_H
#define LSRAM_H

#define LSRAM_MEM_SIZE 1<<16

class lsram : public sc_module {

    public:

        lsram(sc_module_name name);
        
        void store(uint16_t addr, uint8_t val);        
        uint8_t load(uint16_t addr);

        void reset();

    private:
    
        uint8_t _sram[LSRAM_MEM_SIZE];

};

#endif // LSRAM_H
