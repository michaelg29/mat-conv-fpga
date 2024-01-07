
#include "core.h"
#include "system.h"
#include "systemc.h"

#include <iostream>

core::core(sc_module_name name, uint8_t kern_dim)
    : sc_module(name), _kern_dim(kern_dim)
{

}

/** Process the first five bytes of each array argument. */
uint32_t core::calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t *group) {
    for (int i = 0; i < _kern_dim; ++i) {
        carry += (uint32_t)kern_row[i] * (uint32_t)group[i];
    }

    // round and truncate after each dot product
    //carry += 1 << 3; // add 2^-4 (in SQ.7)
    //carry >>= 4;     // truncate 4 fractional bits

    // output 18 bits
    return carry & 0x3ffff;
}
