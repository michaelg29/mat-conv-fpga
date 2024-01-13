
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

bool core::get_row_result(uint32_t &res) {
    // output 18 bits
    res = _result & 0x3ffff;
    return _res_valid;
}

void core::reset() {
    if (_kern_dim) {
        memset(_kern_row, 0, _kern_dim);
        memset(_group, 0, _kern_dim);
    }
    
    _enable = false;
    _res_valid = false;
    _result = 0;
}

void core::main() {
    // local copies for processing
    bool enable;
    uint32_t result;
    uint32_t prevres;
    uint8_t kern_row[_kern_dim];
    uint8_t group[_kern_dim];

    while (true) {
        // capture values on posedge
        enable = _enable;
        result = _result;
        prevres = _result;
        memcpy(kern_row, _kern_row, _kern_dim);
        memcpy(group, _group, _kern_dim);
        YIELD();

        // compute and update
        if (enable) {
            for (int i = 0; i < _kern_dim; ++i) {
                result += (uint32_t)kern_row[i] * (uint32_t)group[i];
            }
            LOGF("[%s]: computed new result %08x = %08x + (%02x %02x %02x %02x %02x).(%02x %02x %02x %02x %02x)",
                this->name(), result, prevres,
                kern_row[0], kern_row[1], kern_row[2], kern_row[3], kern_row[4],
                group[0], group[1], group[2], group[3], group[4]
                );
            _res_valid = true;
            _enable = false;
            _result = result;
        }
        else {
            _res_valid = false;
        }

        // next posedge
        POS_CORE();
    }
}