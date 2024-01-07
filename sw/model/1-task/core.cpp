
#include "core.h"
#include "system.h"
#include "systemc.h"

core::core(sc_module_name name, uint8_t kern_dim)
    : sc_module(name), _kern_dim(kern_dim)
{
    // allocate memory
    if (kern_dim) {
        _kern_row = new uint8_t[kern_dim];
        _group = new uint8_t[kern_dim];
    }

    SC_THREAD(main);
}

core::~core() {
    if (_kern_dim) {
        delete _kern_row;
        delete _group;
    }
}

/** Process the first five bytes of each array argument. */
void core::calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t *group) {
    // copy memory
    memcpy(_kern_row, kern_row, _kern_dim);
    memcpy(_group, group, _kern_dim);
    _result = carry;

    // enable
    _enable = true;
}

uint32_t core::get_row_result() {
    // output 18 bits
    return _result & 0x3ffff;
}

void core::main() {
    // local copies for processing
    bool enable;
    uint8_t kern_row[_kern_dim];
    uint8_t group[_kern_dim];

    while (true) {
        // capture values on posedge
        enable = _enable;
        memcpy(kern_row, _kern_row, _kern_dim);
        memcpy(group, _group, _kern_dim);
        YIELD();

        // compute and modify
        if (enable) {
            for (int i = 0; i < _kern_dim; ++i) {
                _result += (uint32_t)kern_row[i] * (uint32_t)group[i];
            }
            _enable = false;
            LOGF("[%s]: computed new result %08x", this->name(), _result);
        }

        POS_CORE(); // next posedge
    }
}
