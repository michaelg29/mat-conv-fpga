
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

int mat_mult_if::send_cmd(uint8_t *ext_mem, unsigned int cmd_type, unsigned int rows, unsigned int cols, unsigned int tx_addr, unsigned int out_addr) {
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

    // read ack
    memcpy(&_ack, ext_mem + _cmd.tx_addr, sizeof(_ack));

    // verify acknowledge packet
    if (!CMP_CMD_ACK(_cmd, _ack)) {
        std::cerr << "ERROR>>> Acknowledge packet does not match command." << std::endl;
    }
    std::cout << "Ack trans_id is " << _ack.trans_id << " for transaction " << _cmd.trans_id << " and status is " << _ack.status << std::endl;

    // return the status
    return _ack.status;
}

int mat_mult_if::send_payload(uint8_t *ext_mem, unsigned int start_addr, unsigned int rows, unsigned int cols) {
    // calculate number of packets to send
    int n = rows * cols;
    if (n & 0b111) {
        n += 8;
    }
    n >>= 3;

    // send payload
    _packets = (uint64_t*)(ext_mem + start_addr);
    for (int i = 0; i < n; ++i) {
        // generate address to wrap
        uint64_t addr = (uint64_t)(i & 0b11); // wrap every 4 packets
        addr <<= 3; // shift to 64-bit boundary
        addr += OFFSET_PAYLOAD; // add offset

        // transmit
        receive_packet(addr, _packets[i]);
    }

    // read ack
    memcpy(&_ack, ext_mem + _cmd.tx_addr, sizeof(_ack));

    // verify acknowledge packet
    if (!CMP_CMD_ACK(_cmd, _ack)) {
        std::cerr << "ERROR>>> Acknowledge packet does not match command." << std::endl;
    }
    std::cout << "Ack trans_id is " << _ack.trans_id << " for transaction " << _cmd.trans_id << " and status is " << _ack.status << std::endl;

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
    case WAIT_CMD_KERN_SKEY:
    {
        _cur_ack.status = MM_STAT_OKAY;

        if (_cur_cmd.s_key != MM_S_KEY) _cur_ack.status |= MM_STAT_ERR_KEY;

        if (GET_CMD_TYPE(_cur_cmd) != MM_CMD_KERN) _cur_ack.status |= MM_STAT_ERR_ORD;

        // latch in acknowledge message
        _cur_ack.s_key = MM_S_KEY;
        _cur_ack.command = _cur_cmd.command;

        // advance state
        _next_state = WAIT_CMD_SIZE;
        std::cout << "WAIT_CMD_KERN_SKEY " << _cur_ack.status << std::endl;
        break;
    }
    case WAIT_CMD_SUBJ_SKEY:
    {
        _cur_ack.status = MM_STAT_OKAY;

        if (_cur_cmd.s_key != MM_S_KEY) _cur_ack.status |= MM_STAT_ERR_KEY;

        if ((GET_CMD_TYPE(_cur_cmd)) != (MM_CMD_SUBJ)) _cur_ack.status |= MM_STAT_ERR_ORD;

        // latch in acknowledge message
        _cur_ack.s_key = MM_S_KEY;
        _cur_ack.command = _cur_cmd.command;

        // advance state
        _next_state = WAIT_CMD_SIZE;
        std::cout << "WAIT_CMD_SUBJ_SKEY " << _cur_ack.status << std::endl;
        break;
    }
    case WAIT_CMD_SIZE:
    {
        uint16_t rows = (uint16_t)(GET_CMD_SIZE_ROWS(_cur_cmd));
        uint16_t cols = (uint16_t)(GET_CMD_SIZE_COLS(_cur_cmd));
        if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN &&
            ((rows != cols) ||      // kernel must be square
            ((rows & 0b1) == 0) ||  // kernel must have an odd dimension
            (rows > MAX_KERN_DIM))) // kernel size constraint
            _cur_ack.status |= MM_STAT_ERR_SIZE;

        if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ &&
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

        // write ack packet to CPU
        uint64_t *packets = (uint64_t*)&_cur_ack;
        for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
            mem_if->write((uint64_t)(_cur_cmd.tx_addr), *packets);

            // advance cursors
            _cur_cmd.tx_addr += 8;
            packets += 1;
        }

        // raise interrupt

        if (_cur_ack.status == MM_STAT_OKAY) {
            // advance state
            _next_state = WAIT_DATA;
        }
        else {
            // advance state
            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
                _next_state = WAIT_CMD_KERN_SKEY;
            }
            else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                _next_state = WAIT_CMD_SUBJ_SKEY;
            }
        }

        std::cout << "WAIT_CMD_EKEY " << _cur_ack.status << std::endl;

        break;
    }
    case WAIT_DATA:
    {
        if (_regs.status_reg.ready) {
            // advance state
            if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_KERN) {
                _next_state = WAIT_CMD_SUBJ_SKEY;
            }
            else if (GET_CMD_TYPE(_cur_cmd) == MM_CMD_SUBJ) {
                _next_state = WAIT_CMD_KERN_SKEY;
            }
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
    _cur_state = WAIT_CMD_KERN_SKEY;
}

mat_mult_cmd::mat_mult_cmd(sc_module_name name, uint8_t *memory, int kernel_size)
    : sc_module(name), _memory(memory), _kernel_size(kernel_size)
{
    SC_THREAD(do_mat_mult);
}

void mat_mult_cmd::do_mat_mult() {
    std::cout << "Starting" << std::endl;
    mm_if->reset();
    std::cout << "Done reset" << std::endl;

    mm_if->send_cmd(_memory, MM_CMD_KERN, _kernel_size, _kernel_size, UNUSED_ADDR, 0);
    std::cout << "Done kernel cmd" << std::endl;

    mm_if->send_payload(_memory, KERN_ADDR, _kernel_size, _kernel_size);
    std::cout << "Done kernel payload" << std::endl;

    mm_if->send_cmd(_memory, MM_CMD_SUBJ, MAT_ROWS, MAT_COLS, UNUSED_ADDR, OUT_ADDR);
    std::cout << "Done subject cmd" << std::endl;

    mm_if->send_payload(_memory, MAT_ADDR, MAT_ROWS, MAT_COLS);
    std::cout << "Done subject payload" << std::endl;
}
