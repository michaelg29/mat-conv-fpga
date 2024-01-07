
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
        virtual void calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t *group) = 0;

        /** Return the result of the previous computation. */
        virtual uint32_t get_row_result() = 0;

};

class core : public sc_module, public core_if {

    public:

        /** Constructor. */
        SC_HAS_PROCESS(core);
        core(sc_module_name name, uint8_t kern_dim = MAX_KERN_DIM);

        /** Destructor. */
        ~core();

        /** Process the first `_kern_dim` bytes of each array argument. */
        void calculate_row_result(uint32_t carry, uint8_t *kern_row, uint8_t *group);

        /** Return the result of the previous computation. */
        uint32_t get_row_result();

    private:

        /** Configuration. */
        uint8_t _kern_dim;

        /** Buffers. */
        bool _enable;
        uint8_t *_kern_row;
        uint8_t *_group;
        uint32_t _result;

        /** Main thread function. */
        void main();

};

#endif // CORE_H
