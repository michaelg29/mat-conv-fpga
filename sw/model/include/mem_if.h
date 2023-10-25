
#include "systemc.h"

#ifndef MEM_IF_H
#define MEM_IF_H

/**
 * Interface with memory to be overridden for different abstraction levels.
 */
class mem_if : virtual public sc_interface {

    public:

        virtual bool write(uint64_t addr, uint64_t data) = 0;
        virtual bool read(uint64_t addr, uint64_t& data) = 0;

};

#endif // MEM_IF_H
