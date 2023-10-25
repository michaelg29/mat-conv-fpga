
#include "systemc.h"
#include "system.h"

#ifndef CORE_H
#define CORE_H

class core : public sc_module {

    public:

        core(sc_module_name name);

        /** Compute one MLA operation. Computes its internal kernelVal*sVal + addInput */
        int32_t compute_result(uint8_t sVal, uint32_t addInput);

        void setKernelValue(uint8_t val);        
        void reset();

    private:
    
        uint8_t _kVal;

};

#endif // CORE_H
