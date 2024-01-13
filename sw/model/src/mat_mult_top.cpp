
#include "systemc.h"

#include "mat_mult_if.h"
#include "mat_mult_cmd.h"
#include "mat_mult_top.h"
#include "system.h"

mat_mult_top::mat_mult_top(sc_module_name name)
    : sc_module(name), mat_mult_if()
{

}

void mat_mult_top::calculate_next_state() {
    switch (_cur_state) {
    case WAIT_CMD_SKEY:
    {
        _cur_ack.status = MM_STAT_OKAY;

        if (_cur_cmd.s_key != MM_S_KEY) _cur_ack.status |= MM_STAT_ERR_KEY;

        // latch in acknowledge message
        _cur_ack.s_key = MM_S_KEY;
        _cur_ack.command = _cur_cmd.command;

        // latch in register
        if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
            _regs.cmd_type_reg.is_kern = true;
            _regs.cmd_type_reg.is_subj = false;
        }
        else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
            _regs.cmd_type_reg.is_kern = false;
            _regs.cmd_type_reg.is_subj = true;
        }

        // advance state
        _next_state = WAIT_CMD_SIZE;
        LOGF("WAIT_CMD_SKEY: received %08x, %08x, new status %d", _cur_cmd.s_key, _cur_cmd.command, _cur_ack.status);
        break;
    }
    case WAIT_CMD_SIZE:
    {
        uint16_t rows = (uint16_t)(GET_CMD_SIZE_ROWS(_cur_cmd));
        uint16_t cols = (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
        if (_regs.cmd_type_reg.is_kern &&
            ((rows != cols) ||      // kernel must be square
            ((rows & 0b1) == 0) ||  // kernel must have an odd dimension
            (rows > MAX_KERN_DIM))) // kernel size constraint
            _cur_ack.status |= MM_STAT_ERR_SIZE;

        else if (_regs.cmd_type_reg.is_subj &&
            (cols & 0b111) != 0)    // subject columns must be divisible by 8
            _cur_ack.status |= MM_STAT_ERR_SIZE;

        std::cout << rows << "x" << cols << std::endl;

        // latch in acknowledge message
        _cur_ack.size = _cur_cmd.size;
        _cur_ack.tx_addr = _cur_cmd.tx_addr;

        // advance state
        _next_state = WAIT_CMD_TID;
        LOGF("WAIT_CMD_SIZE: received %08x, %08x, new status %d", _cur_cmd.size, _cur_cmd.tx_addr, _cur_ack.status);
        break;
    }
    case WAIT_CMD_TID:
    {
        // latch in acknowledge message
        _cur_ack.trans_id = _cur_cmd.trans_id;

        // advance state
        _next_state = WAIT_CMD_EKEY;
        LOGF("WAIT_CMD_TID: received %08x, %08x, new status %d", _cur_cmd.trans_id, _cur_cmd.reserved, _cur_ack.status);
        break;
    }
    case WAIT_CMD_EKEY:
    {
        if (_cur_cmd.e_key != MM_E_KEY) _cur_ack.status |= MM_STAT_ERR_KEY;
        if (((uint32_t)_cur_cmd.chksum) != ((uint32_t)CALC_CMD_CHKSUM(_cur_cmd))) _cur_ack.status |= MM_STAT_ERR_CHKSM;

        // latch in acknowledge message
        _cur_ack.e_key = MM_E_KEY;
        _cur_ack.chksum = (uint32_t)CALC_ACK_CHKSUM(_cur_ack);

        if (_cur_ack.status == MM_STAT_OKAY) {
            // advance state
            _next_state = WAIT_DATA;
        }
        else {
            // advance state
            if (_regs.cmd_type_reg.is_kern) {
                _next_state = WAIT_CMD_SKEY;
            }
            else if (_regs.cmd_type_reg.is_subj) {
                _next_state = WAIT_CMD_SKEY;
            }
        }

        LOGF("WAIT_CMD_EKEY: received %08x, %08x, new status %d", _cur_cmd.e_key, _cur_cmd.chksum, _cur_ack.status);
        break;
    }
    case WAIT_DATA:
    {
        if (_regs.status_reg.ready) {
            // advance state
            _next_state = WAIT_CMD_SKEY;
        }
        break;
    }
    default:
    {
        break;
    }
    };
}

void mat_mult_top::advance_state() {
    _cur_state = _next_state;
}

void mat_mult_top::protected_reset() {
    _cur_state = WAIT_CMD_SKEY;
}

void mat_mult_top::write_ack() {
    // write ack packet to CPU
    uint64_t *packets = (uint64_t*)&_cur_ack;
    for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
        mem_if->write((uint64_t)(_cur_cmd.tx_addr), *packets);

        // advance cursors
        _cur_cmd.tx_addr += 8;
        packets += 1;
    }

    // raise interrupt
    cmd_if->raise_interrupt();
}

