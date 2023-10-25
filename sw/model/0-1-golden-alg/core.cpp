
#include "core.h"
#include "system.h"
#include "systemc.h"

#include <iostream>

core::core(sc_module_name name) : sc_module(name) {

}

/** Process the first five bytes of each array argument. */
uint32_t core::calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t *group) {
    for (int i = 0; i < MAX_KERN_ROWS; ++i) {
        carry += kern_row[i] * group[i];
    }
    
    return carry;
}
