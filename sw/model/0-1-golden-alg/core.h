
#include "system.h"

#include "systemc.h"

#ifndef CORE_H
#define CORE_H

/**
 * @brief Interface to interact with internal compute cores.
 */
class core_if : virtual public sc_interface {

    public:

        /** Process the first `kern_dim` bytes of each array argument. */
        virtual uint32_t calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t *group) = 0;

};

class core : public sc_module, public core_if {

    public:

        /** Constructor. */
        core(sc_module_name name, uint8_t kern_dim = MAX_KERN_DIM);

        /** Process the first `_kern_dim` bytes of each array argument. */
        uint32_t calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t *group);

    private:

        uint8_t _kern_dim;

};

#endif // CORE_H
