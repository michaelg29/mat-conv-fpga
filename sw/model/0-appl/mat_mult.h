
#include "systemc.h"
#include "system.h"
#include "mat_mult_if.h"

#ifndef MAT_MULT_H
#define MAT_MULT_H

class mat_mult : public mat_mult_top {

    public:

        /** Constructor. */
        mat_mult(sc_module_name name);

    protected:

        /** Receive a 64-bit packet. */
        bool receive_packet(uint64_t addr, uint64_t packet);

        /** Reset function to be overridden and called by subclasses. */
        void protected_reset();

        // state variables
        uint64_t *_cur_ptr;
        uint32_t _expected_el;
        uint32_t _loaded_el;
        uint8_t _kern_dim;
        uint8_t _hf_kern_dim;

    private:

        // internal memories
        uint8_t subj_mem[MAT_SIZE];
        uint8_t kern_mem[KERN_SIZE_ROUNDED];

        void calculate();

};

#endif // MAT_MULT_H
