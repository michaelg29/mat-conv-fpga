
#include "core.h"
#include "system.h"
#include "systemc.h"

#include <iostream>

core::core(sc_module_name name) : sc_module(name) {

}

/** Process the first five bytes of each array argument. */
int32_t core::calculate_row_result(uint8_t *kern_row, uint8_t *group) {
    _res = 0;
    
    for (int i = 0; i < 5; ++i) {
        _res += kern_row[i] * group[i];
    }
    
    return _res;
}
