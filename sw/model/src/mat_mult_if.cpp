
#include "systemc.h"

#include "mat_mult_if.h"
#include "mat_mult_cmd.h"
#include "mat_mult_top.h"
#include "system.h"

// generate command field
#define GEN_COMMAND(type, out_addr) \
    ((type & 0b1) << 30) | ((out_addr & 0xffffffff) >> 3)

// generate size field
#define GEN_KERN_SIZE(rows, cols) \
    ((((rows * cols) & 0xffff) << 16) | ((rows & 0x7ff) << 5) | (cols & 0x1f))
#define GEN_SUBJ_SIZE(rows, cols) \
    (((((rows >> 1) * (cols >> 7)) & 0xffff) << 16) | (((rows >> 1) & 0x7ff) << 5)  | ((cols >> 7) & 0x1f))


mat_mult_if::mat_mult_if()
    : _cur_trans_id(0)
{

}

void mat_mult_if::send_cmd(uint8_t *ext_mem, unsigned int cmd_type, unsigned int rows, unsigned int cols, unsigned int tx_addr, unsigned int out_addr, unsigned int in_addr) {
    // construct command
    _cmd.s_key    = MM_S_KEY;
    _cmd.command  = GEN_COMMAND(cmd_type, out_addr);
    if (cmd_type == MM_CMD_KERN) {
        _cmd.size = GEN_KERN_SIZE(rows, cols);
    }
    else if (cmd_type == MM_CMD_SUBJ) {
        _cmd.size = GEN_SUBJ_SIZE(rows, cols);
    }
    _cmd.tx_addr  = tx_addr;
    _cmd.trans_id = _cur_trans_id;
    _cmd.reserved = 0;
    _cmd.e_key    = MM_E_KEY;
    _cmd.chksum   = CALC_CMD_CHKSUM(_cmd);

    LOGF("[mat_mult_if] Commanding to write to %d", out_addr);

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
        uint64_t addr = (uint64_t)(i & 0xf); // wrap every 16 packets
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
    LOGF("[mat_mult_if] Ack trans_id is %d for transaction %d and status is %d", _ack.trans_id, _cmd.trans_id, _ack.status);
    if (!CMP_CMD_ACK(_cmd, _ack)) {
        LOG("[mat_mult_if] ERROR>>> Acknowledge packet does not match command.");
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
    _cur_trans_id = 0;
}
