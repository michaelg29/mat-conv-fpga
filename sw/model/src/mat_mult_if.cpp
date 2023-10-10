
#include "systemc.h"

#include "mat_mult_if.h"

// generate command field
#define GEN_COMMAND(type, out_addr) \
    ((type & 0b1) << 30) | (out_addr & 0xffffffff) >> 2)

// generate size field
#define GEN_SIZE(rows, cols) \
    ((rows & 0xffff) << 16) | (cols & 0xffff)

// calculate the checksum of a command packet
#define CALC_CHKSUM(cmd) \
    cmd.s_key ^ cmd.command ^ cmd.size ^ cmd.tx_addr ^ cmd.trans_id ^ cmd.res ^ cmd.e_key

mat_mult_if::mat_mult_if(sc_module_name name) : sc_module(name) {

}

int mat_mult_if::loadKernel(unsigned char *mem, unsigned int start_addr, unsigned int kern_size, unsigned int tx_addr) {
    // construct command
    _cmd.s_key    = MM_S_KEY;
    _cmd.command  = GEN_COMMAND(MM_CMD_KERN, 0);
    _cmd.size     = GEN_SIZE(kern_size, kern_size); 
    _cmd.tx_addr  = tx_addr;
    _cmd.trans_id = 1;
    _cmd.reserved = 0;
    _cmd.e_key    = MM_E_KEY;
    _cmd.chksum   = CALC_CHKSUM(_cmd);
    
    // send command
    uint64 *packets = (uint64*)&_cmd;
    for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
        transmit64bitPacket(packets[i]);
    }
    
    // send payload
    packets = (uint64*)mem;
    for (int i = 0, n = kern_size * kern_size; i < n; i += 8) {
        transmit64bitPacket(packets[i]);
    }
}

int mat_mult_if::loadSubject(unsigned char *mem, unsigned int start_addr, unsigned int subj_rows, unsigned int subj_cols, unsigned int tx_addr, unsigned int out_addr) {
    // construct command
    _cmd.s_key    = MM_S_KEY;
    _cmd.command  = GEN_COMMAND(MM_CMD_SUBJ, out_addr);
    _cmd.size     = GEN_SIZE(subj_rows, subj_cols); 
    _cmd.tx_addr  = tx_addr;
    _cmd.trans_id = 1;
    _cmd.reserved = 0;
    _cmd.e_key    = MM_E_KEY;
    _cmd.chksum   = CALC_CHKSUM(_cmd);
    
    // send command
    uint64 *packets = (uint64*)&_cmd;
    for (int i = 0; i < N_PACKETS_IN_CMD; ++i) {
        transmit64bitPacket(packets[i]);
    }
    
    // send payload
    packets = (uint64*)mem;
    for (int i = 0, n = subj_rows * subj_cols; i < n; i += 8) {
        transmit64bitPacket(packets[i]);
    }
}
