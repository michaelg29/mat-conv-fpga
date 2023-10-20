
#include "systemc.h"
#include "system.h"

#ifndef CORE_H
#define CORE_H

class core : public sc_module {

    public:

        core(sc_module_name name);

        /** Process the first five bytes of each array argument. */
        int32_t calculate_row_result(uint8_t *kern_row, uint8_t *group);

    private:
    
        int32_t _res;

};

#endif // CORE_H
