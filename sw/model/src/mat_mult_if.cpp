
#include "systemc.h"

#include "mat_mult_if.h"

// generate command field
#define GEN_COMMAND(type, out_addr) \
    ((type & 0b1) << 30) | ((out_addr & 0xffffffff) >> 2)

// generate size field
#define GEN_SIZE(rows, cols) \
    ((rows & 0xffff) << 16) | (cols & 0xffff)


mat_mult_if::mat_mult_if(sc_module_name name, uint8_t *ext_mem)
    : sc_module(name), _ext_mem(ext_mem), _cur_trans_id(1)
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
        transmit64bitPacket(0, packets[i]);
    }
    
    // read ack
    memcpy(&_ack, _ext_mem + _cmd.tx_addr, sizeof(_ack));
    
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
        transmit64bitPacket(0, packets[i]);
    }
    
    // read ack
    memcpy(&_ack, _ext_mem + _cmd.tx_addr, sizeof(_ack));
    
    _cur_trans_id++;
    
    return _ack.status;
}

int mat_mult_if::loadKernelCmd(unsigned int kern_size, unsigned int tx_addr) {
    // construct command
    _cmd.s_key    = MM_S_KEY;
    _cmd.command  = GEN_COMMAND(MM_CMD_KERN, 0);
    _cmd.size     = GEN_SIZE(kern_size, kern_size); 
    _cmd.tx_addr  = tx_addr;
    _cmd.trans_id = _cur_trans_id;
    _cmd.reserved = 0;
    _cmd.e_key    = MM_E_KEY;
    _cmd.chksum   = CALC_CMD_CHKSUM(_cmd);
    
    // send command
    uint64_t *packets = (uint64_t*)&_cmd;
    for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
        transmit64bitPacket(0, packets[i]);
    }
    
    // read ack
    memcpy(&_ack, _ext_mem + _cmd.tx_addr, sizeof(_ack));
    
    return _ack.status;
}

int mat_mult_if::loadKernelPayload(unsigned int start_addr, unsigned int kern_size) {
    // calculate number of packets to send
    int n = kern_size * kern_size;
    if (n & 0b111) {
        n += 8;
    }
    n >>= 3;
    
    // send payload
    uint64_t *packets = (uint64_t*)(_ext_mem + start_addr);
    std::cout << n << " packets" << std::endl;
    for (int i = 0; i < n; ++i) {
        printf("%016lx\n", packets[i]);
        transmit64bitPacket(0, packets[i]);
    }
    
    // read ack
    memcpy(&_ack, _ext_mem + _cmd.tx_addr, sizeof(_ack));
    
    _cur_trans_id++;
    
    return _ack.status;
}

int mat_mult_if::loadSubjectCmd(unsigned int subj_rows, unsigned int subj_cols, unsigned int tx_addr, unsigned int out_addr) {
    // construct command
    _cmd.s_key    = MM_S_KEY;
    _cmd.command  = GEN_COMMAND(MM_CMD_SUBJ, out_addr);
    _cmd.size     = GEN_SIZE(subj_rows, subj_cols); 
    _cmd.tx_addr  = tx_addr;
    _cmd.trans_id = _cur_trans_id;
    _cmd.reserved = 0;
    _cmd.e_key    = MM_E_KEY;
    _cmd.chksum   = CALC_CMD_CHKSUM(_cmd);
    
    // send command
    uint64_t *packets = (uint64_t*)&_cmd;
    for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
        transmit64bitPacket(0, packets[i]);
    }
    
    // read ack
    memcpy(&_ack, _ext_mem + tx_addr, sizeof(_ack));
    
    return _ack.status;
}

int mat_mult_if::loadSubjectPayload(unsigned int start_addr, unsigned int subj_rows, unsigned int subj_cols) {
    // calculate number of packets to send
    int n = subj_rows * subj_cols;
    if (n & 0b111) {
        n += 8;
    }
    n >>= 3;
    
    // send payload
    uint64_t *packets = (uint64_t*)(_ext_mem + start_addr);
    std::cout << "Sending " << n << " 64-bit packets starting at " << start_addr << std::endl;
    for (int i = 0; i < n; ++i) {
        //std::cout << i << std::endl;
        transmit64bitPacket(0, packets[i]);
    }
    std::cout << "Reading ack at " << _cmd.tx_addr << std::endl;
    
    // read ack
    memcpy(&_ack, _ext_mem + _cmd.tx_addr, sizeof(_ack));
    
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
