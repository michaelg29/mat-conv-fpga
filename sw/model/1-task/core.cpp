
#include "core.h"
#include "system.h"
#include "systemc.h"

core::core(sc_module_name name, uint8_t kern_dim)
    : sc_module(name), _kern_dim(kern_dim),
    _rst("rst"), _enable("enable"), _res_valid("res_valid"), _carry("carry"), _result("result")
{
    // allocate memory
    if (kern_dim) {
        _kern_row = new uint8_t[kern_dim];
        _group = new uint8_t[kern_dim];
    }

    _rst.write(SC_LOGIC_0);
    _enable.write(SC_LOGIC_0);
    _res_valid.write(SC_LOGIC_0);
    _result.write(0);

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
    _carry.write(carry);

    // assert enable signal
    _enable.write(SC_LOGIC_1);
    _rst.write(SC_LOGIC_0);
}

bool core::get_row_result(uint32_t &res) {
    // output 18 bits
    res = _result.read() & 0x3ffff;
    return _res_valid.read().to_bool();
}

void core::reset() {
    // assert reset signal
    _rst.write(SC_LOGIC_1);
}

void core::main() {
    // local copies for processing
    bool rst, enable;
    uint32_t result;
    uint32_t carry;
    uint8_t kern_row[_kern_dim];
    uint8_t group[_kern_dim];

    while (true) {
        // capture values on posedge
        rst = _rst.read().to_bool();
        enable = _enable.read().to_bool();
        carry = _carry.read();
        memcpy(kern_row, _kern_row, _kern_dim);
        memcpy(group, _group, _kern_dim);
        YIELD();

        // compute and update
        if (_enable.read().to_bool() && !rst) {
            // perform computation
            result = carry;
            for (int i = 0; i < _kern_dim; ++i) {
                result += (uint32_t)kern_row[i] * (uint32_t)group[i];
            }

            DEBUGF("[%s]: computed new result %08x = %08x + (%02x %02x %02x %02x %02x).(%02x %02x %02x %02x %02x)",
                this->name(), result, carry,
                kern_row[0], kern_row[1], kern_row[2], kern_row[3], kern_row[4],
                group[0], group[1], group[2], group[3], group[4]
                );

            // assert valid signals
            _res_valid.write(SC_LOGIC_1);
            _result.write(result);
        }
        else {
            _res_valid.write(SC_LOGIC_0);
        }

        // next posedge
        POS_CORE();
    }
}
