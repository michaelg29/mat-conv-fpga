
#include "systemc.h"

#include "mat_mult_if.h"
#include "mat_mult_cmd.h"
#include "mat_mult_top.h"
#include "system.h"

mat_mult_cmd::mat_mult_cmd(sc_module_name name, uint8_t *memory, int kernel_size, bool extra_padding, bool do_wait)
    : sc_module(name), _memory(memory), _kernel_size(kernel_size), _extra_padding(extra_padding), _do_wait(do_wait)
{
    SC_THREAD(do_mat_mult);
}

void mat_mult_cmd::do_mat_mult() {
    wait(CC_CORE(10), SC_NS);
    mm_if->reset();
    LOGF("[%s] Done startup and reset", this->name());

    // send kernel
    _verif_ack = false;
    _sent_subject = false;
    mm_if->send_cmd(_memory, MM_CMD_KERN, _kernel_size, _kernel_size, UNUSED_ADDR, 0, KERN_ADDR);
    LOGF("[%s] Done kernel", this->name());

    // wait until acknowledge verified
    while (!_verif_ack) {
        if (_do_wait) POS_PROC();
    }

    // send subject
    _verif_ack = false;
    _sent_subject = true;
    uint32_t hf_kernel_size = _kernel_size >> 1;
    if (_extra_padding) {
        mm_if->send_cmd(_memory, MM_CMD_SUBJ, MAT_ROWS+hf_kernel_size, MAT_COLS, UNUSED_ADDR, OUT_ADDR, MAT_ADDR);
    }
    else {
        mm_if->send_cmd(_memory, MM_CMD_SUBJ, MAT_ROWS, MAT_COLS, UNUSED_ADDR, OUT_ADDR, MAT_ADDR);
    }
    LOGF("[%s] Done subject", this->name());

    // wait until acknowledge verified
    while (!_verif_ack) {
        if (_do_wait) POS_PROC();
    }
}

void mat_mult_cmd::raise_interrupt() {
    LOGF("[%s] Received interrupt", this->name());

    if (mm_if->verify_ack(_memory, UNUSED_ADDR)) {
        LOGF("[%s] Error in ack packet", this->name());
        sc_stop();
        return;
    }

    _verif_ack = true;
    if(_sent_subject) {
        // done with subject
        LOGF("[%s] Done!", this->name());
        sc_stop();
    }
}
