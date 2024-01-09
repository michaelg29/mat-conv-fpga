
#include "systemc.h"
#include "mat_mult_if.h"

#ifndef MAT_MULT_CMD_H
#define MAT_MULT_CMD_H

/**
 * Interface with the command host to issue interrupts.
 */
class cmd_host_if : virtual public sc_interface {

    public:

        /** Issue an interrupt to the module. */
        virtual void raise_interrupt() = 0;

};

/**
 * Module to issue commands to the matrix multiplier.
 */
class mat_mult_cmd : public sc_module, public cmd_host_if {

    public:

        /** Interface with module. */
        sc_port<mat_mult_if> mm_if;

        SC_HAS_PROCESS(mat_mult_cmd);

        /**
         * @brief Constructor.
         *
         * @param name          Module name.
         * @param memory        Pointer to memory for the command host.
         * @param kernel_size   Size of the kernel.
         * @param extra_padding Whether to send the input matrix with extra rows of padding.
         * @param do_wait       Wait simulation time before checking interrupt flag.
         */
        mat_mult_cmd(sc_module_name name, uint8_t *memory, int kernel_size, bool extra_padding = false, bool do_wait = false);

        /** Execute the command sequence. */
        void do_mat_mult();

        /** cmd_host_if.raise_interrupt */
        void raise_interrupt();

    private:

        /** Runtime configuration parameters. */
        bool _extra_padding;
        bool _do_wait;
        uint8_t *_memory;
        int _kernel_size;

        /** Internal state. */
        bool _verif_ack;
        bool _sent_subject;

};

#endif // MAT_MULT_CMD_H
