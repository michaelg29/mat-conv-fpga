
#include "system.h"
#include "core_if.h"

#include "systemc.h"

#ifndef CORE_H
#define CORE_H

class core : public sc_module, public core_if {

    public:

        /** Constructor. */
        core(sc_module_name name);

        /** Process the first `kern_dim` bytes of each array argument. */
        uint32_t calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t kern_dim, uint8_t *group);

    private:

};

#endif // CORE_H
