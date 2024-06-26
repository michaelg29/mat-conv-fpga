
#include "lsram.h"
#include "system.h"
#include "systemc.h"


lsram::lsram(sc_module_name name) : sc_module(name) {

}

void lsram::store(uint16_t addr, uint8_t val) {

    _sram[addr] = val;

}      

uint8_t lsram::load(uint16_t addr) {
    return  _sram[addr];
}

void lsram::reset() {
    for(int i = 0; i < LSRAM_MEM_SIZE; i++){
        _sram[i] = 0;
    }
}
