
#include "core.h"
#include "system.h"
#include "systemc.h"

#include <iostream>

core::core(sc_module_name name) : sc_module(name) {

}

/** Process the first five bytes of each array argument. */
void core::compute_result(uint8_t sVal) {
    
    *forward = _kVal * sVal + addInput;
}

void core::reset(){
    _kVal = 0;
}

void core::setKernelValue(uint8_t val){
    _kVal = val;
}
