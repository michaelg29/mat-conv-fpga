
#include "systemc.h"
#include "mat_mult_if.h"
#include "mat_mult_cmd.h"
#include "memory_if.hpp"

#ifndef MAT_MULT_TOP_H
#define MAT_MULT_TOP_H

/**
 * Top-level virtual wrapper for the matrix multiplier.
 */
class mat_mult_top : public mat_mult_if, public sc_module {

    public:

        sc_port<memory_if<uint64_t>> mem_if;
        sc_port<cmd_host_if> cmd_if;

        mat_mult_top(sc_module_name name);

    protected:

        /** Register collection. */
        mat_mult_reg_t _regs;

        /** Internal state. */
        mat_mult_cmd_t _cur_cmd;
        mat_mult_ack_t _cur_ack;
        mat_mult_state_e _cur_state;
        mat_mult_state_e _next_state;

        /** Required subclass overrides. */
        virtual bool receive_packet(uint64_t addr, uint64_t packet) = 0;
        void protected_reset();

        /**
         * @brief Calculate the next state using the current state.
         */
        void calculate_next_state();

        /**
         * @brief Assign the _next_state to _cur_state.
         */
        void advance_state();

        /**
         * @brief Write the current acknowledge packet to the command host, then issue an interrupt.
         */
        void write_ack();

};

#endif // MAT_MULT_TOP_H
