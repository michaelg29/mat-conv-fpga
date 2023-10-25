
#include "systemc.h"

#include "mat_mult_if.h"

// generate command field
#define GEN_COMMAND(type, out_addr) \
    ((type & 0b1) << 30) | ((out_addr & 0xffffffff) >> 3)

// generate size field
#define GEN_SIZE(rows, cols) \
    ((rows & 0xffff) << 16) | (cols & 0xffff)


mat_mult_if::mat_mult_if(uint8_t *ext_mem)
    : _ext_mem(ext_mem), _cur_trans_id(1)
{

}

int mat_mult_if::sendCmd(unsigned int cmd_type, unsigned int rows, unsigned int cols, unsigned int tx_addr, unsigned int out_addr) {
    // construct command
    _cmd.s_key    = MM_S_KEY;
    _cmd.command  = GEN_COMMAND(cmd_type, out_addr);
    _cmd.size     = GEN_SIZE(rows, cols); 
    _cmd.tx_addr  = tx_addr;
    _cmd.trans_id = _cur_trans_id;
    _cmd.reserved = 0;
    _cmd.e_key    = MM_E_KEY;
    _cmd.chksum   = CALC_CMD_CHKSUM(_cmd);
    
    // send command
    uint64_t *packets = (uint64_t*)&_cmd;
    for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
        receive64bitPacket((i << 3) + OFFSET_COMMAND, packets[i]);
    }
    
    // read ack
    memcpy(&_ack, _ext_mem + _cmd.tx_addr, sizeof(_ack));
    
    if (!CMP_CMD_ACK(_cmd, _ack)) {
        std::cerr << "ERROR>>> Acknowledge packet does not match command." << std::endl;
    }
    std::cout << "Ack trans_id is " << _ack.trans_id << " for transaction " << _cmd.trans_id << " and status is " << _ack.status << std::endl;
    
    return _ack.status;
}

int mat_mult_if::sendPayload(unsigned int start_addr, unsigned int rows, unsigned int cols) {
    // calculate number of packets to send
    int n = rows * cols;
    if (n & 0b111) {
        n += 8;
    }
    n >>= 3;
    
    // send payload
    uint64_t *packets = (uint64_t*)(_ext_mem + start_addr);
    for (int i = 0; i < n; ++i) {
        // generate address to wrap
        uint64_t addr = (uint64_t)(i & 0b11); // wrap every 4 packets
        addr <<= 3; // shift to 64-bit boundary
        addr += OFFSET_PAYLOAD; // add offset
        
        // transmit
        receive64bitPacket(addr, packets[i]);
    }
    
    // read ack
    memcpy(&_ack, _ext_mem + _cmd.tx_addr, sizeof(_ack));
    
    if (!CMP_CMD_ACK(_cmd, _ack)) {
        std::cerr << "ERROR>>> Acknowledge packet does not match command." << std::endl;
    }
    std::cout << "Ack trans_id is " << _ack.trans_id << " for transaction " << _cmd.trans_id << " and status is " << _ack.status << std::endl;
    
    _cur_trans_id++;
    
    return _ack.status;
}

void mat_mult_if::reset() {
    protected_reset();
    private_reset();
}

void mat_mult_if::private_reset() {
    _cur_trans_id = 1;
    regs.status_reg.error = 0;
    regs.status_reg.ready = false;
    regs.status_reg.multiplying = false;
}
