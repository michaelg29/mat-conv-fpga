
#include "systemc.h"
#include "system.h"

#ifndef CORE_H
#define CORE_H

class core_if : virtual public sc_interface {

    public:

        /** Process the first five bytes of each array argument. */
        virtual uint32_t calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t kern_dim, uint8_t *group) = 0;

};

class core : public sc_module, public core_if {

    public:

        /** Constructor. */
        core(sc_module_name name);

        /** Process the first five bytes of each array argument. */
        uint32_t calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t kern_dim, uint8_t *group);

    private:

};

#endif // CORE_H
