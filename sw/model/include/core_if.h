
#include "system.h"

#include "systemc.h"

#ifndef CORE_IF_H
#define CORE_IF_H

/**
 * @brief Interface to interact with internal compute cores.
 */
class core_if : virtual public sc_interface {

    public:

        /** Process the first `kern_dim` bytes of each array argument. */
        virtual uint32_t calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t kern_dim, uint8_t *group) = 0;

};

#endif // CORE_IF_H
