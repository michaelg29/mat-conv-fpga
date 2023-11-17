
#include "systemc.h"
#include "system.h"

#ifndef CORE_H
#define CORE_H

class core : public sc_module {

    public:

        core(sc_module_name name);

        /** Compute one MLA operation. Computes its internal kernelVal*sVal + addInput */
        void compute_result(uint8_t sVal);

        void setKernelValue(uint8_t val);        
        void reset();
        uint32_t addInput=0;
        uint32_t* forward = NULL;

    private:

        int8_t _kVal=0;

};

#endif // CORE_H
