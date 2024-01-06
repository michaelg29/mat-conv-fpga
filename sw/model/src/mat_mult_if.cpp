
#include "systemc.h"

#include "mat_mult_if.h"
#include "system.h"

// generate command field
#define GEN_COMMAND(type, out_addr) \
    ((type & 0b1) << 30) | ((out_addr & 0xffffffff) >> 3)

// generate size field
#define GEN_SIZE(rows, cols) \
    ((rows & 0xffff) << 16) | (cols & 0xffff)


mat_mult_if::mat_mult_if()
    : _cur_trans_id(1)
{

}

void mat_mult_if::send_cmd(uint8_t *ext_mem, unsigned int cmd_type, unsigned int rows, unsigned int cols, unsigned int tx_addr, unsigned int out_addr, unsigned int in_addr) {
    // construct command
    _cmd.s_key    = MM_S_KEY;
    _cmd.command  = GEN_COMMAND(cmd_type, out_addr);
    _cmd.size     = GEN_SIZE(rows, cols);
    _cmd.tx_addr  = tx_addr;
    _cmd.trans_id = _cur_trans_id;
    _cmd.reserved = 0;
    _cmd.e_key    = MM_E_KEY;
    _cmd.chksum   = CALC_CMD_CHKSUM(_cmd);

    std::cout << "Commanding to write to " << out_addr << std::endl;

    // send command
    _packets = (uint64_t*)&_cmd;
    for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
        receive_packet((i << 3) + OFFSET_COMMAND, _packets[i]);
    }

    // calculate number of packets to send
    int n = rows * cols;
    if (n & 0b111) {
        n += 8;
    }
    n >>= 3;

    // send payload
    _packets = (uint64_t*)(ext_mem + in_addr);
    for (int i = 0; i < n; ++i) {
        // generate address to wrap
        uint64_t addr = (uint64_t)(i & 0b11); // wrap every 4 packets
        addr <<= 3; // shift to 64-bit boundary
        addr += OFFSET_PAYLOAD; // add offset

        // transmit
        receive_packet(addr, _packets[i]);
    }
}

int mat_mult_if::verify_ack(uint8_t *ext_mem, unsigned int tx_addr) {
    // read ack
    memcpy(&_ack, ext_mem + _cmd.tx_addr, sizeof(_ack));

    // verify acknowledge packet
    std::cout << "Ack trans_id is " << _ack.trans_id << " for transaction " << _cmd.trans_id << " and status is " << _ack.status << std::endl;
    if (!CMP_CMD_ACK(_cmd, _ack)) {
        std::cerr << "ERROR>>> Acknowledge packet does not match command." << std::endl;
        return MM_STAT_ERR_OTHER;
    }

    // increment transaction ID for next transaction
    _cur_trans_id++;

    // return the status
    return _ack.status;
}

void mat_mult_if::reset() {
    protected_reset();
    private_reset();
}

void mat_mult_if::private_reset() {
    _cur_trans_id = 1;
}

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
        std::cout << "WAIT_CMD_SKEY " << _cur_ack.status << std::endl;
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
        std::cout << "WAIT_CMD_SIZE " << _cur_ack.status << std::endl;
        break;
    }
    case WAIT_CMD_TID:
    {
        // latch in acknowledge message
        _cur_ack.trans_id = _cur_cmd.trans_id;

        // advance state
        _next_state = WAIT_CMD_EKEY;
        std::cout << "WAIT_CMD_TID " << _cur_ack.status << std::endl;
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

        std::cout << "WAIT_CMD_EKEY " << _cur_ack.status << std::endl;

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

mat_mult_cmd::mat_mult_cmd(sc_module_name name, uint8_t *memory, int kernel_size, bool extra_padding)
    : sc_module(name), _memory(memory), _kernel_size(kernel_size), _extra_padding(extra_padding)
{
    SC_THREAD(do_mat_mult);
}

void mat_mult_cmd::do_mat_mult() {
    std::cout << "Starting" << std::endl;
    mm_if->reset();
    std::cout << "Done reset" << std::endl;

    // send kernel
    _verif_ack = false;
    _sent_subject = false;
    mm_if->send_cmd(_memory, MM_CMD_KERN, _kernel_size, _kernel_size, UNUSED_ADDR, 0, KERN_ADDR);
    std::cout << "Done kernel" << std::endl;

    // wait until acknowledge verified
    while (!_verif_ack) {}

    // send subject
    _verif_ack = false;
    _sent_subject = true;
    uint32_t hf_kernel_size = _kernel_size >> 1;
    if (_extra_padding) {
        mm_if->send_cmd(_memory, MM_CMD_SUBJ, MAT_ROWS+hf_kernel_size, MAT_COLS, UNUSED_ADDR, OUT_ADDR, MAT_ADDR);
        std::cout << "Done subject" << std::endl;
    }
    else {
        mm_if->send_cmd(_memory, MM_CMD_SUBJ, MAT_ROWS, MAT_COLS, UNUSED_ADDR, OUT_ADDR, MAT_ADDR);
        std::cout << "Done subject" << std::endl;
    }

    // wait until acknowledge verified
    while (!_verif_ack) {}
}

void mat_mult_cmd::raise_interrupt() {
    std::cout << "interrupt" << std::endl;

    if (mm_if->verify_ack(_memory, UNUSED_ADDR)) {
        std::cerr << "Error in ack packet" << std::endl;
        sc_stop();
        return;
    }

    _verif_ack = true;
    if(_sent_subject) {
        // done with subject
        std::cout << "Done!" << std::endl;
        sc_stop();
    }
}
