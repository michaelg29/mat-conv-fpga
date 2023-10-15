
#include "systemc.h"

#ifndef MAT_MULT_IF_H
#define MAT_MULT_IF_H

#define MM_STAT_OKAY      0b000
#define MM_STAT_ERR_OTHER 0b001
#define MM_STAT_ERR_SIZE  0b010
#define MM_STAT_ERR_ORD   0b011

#define MM_S_KEY 0xCAFECAFE
#define MM_E_KEY 0xDEADBEEF

#define MM_CMD_KERN 0x0
#define MM_CMD_SUBJ 0x1

typedef unsigned int uint32;
typedef unsigned long long uint64;

typedef struct {
    uint32 s_key;
    uint32 command;
    uint32 size;
    uint32 tx_addr;
    uint32 trans_id;
    uint32 reserved;
    uint32 e_key;
    uint32 chksum;
} mat_mult_cmd;

#define N_PACKETS_IN_CMD sizeof(mat_mult_cmd) / sizeof(uint64)

typedef struct {
    
} mat_mult_reg_t;

/**
 * Interface with the matrix multiplier module to issue commands.
 */
class mat_mult_if : public sc_module, virtual public sc_interface {

    public:
    
        // constructor
        mat_mult_if(sc_module_name name);
        
        /** Load the kernel matrix. */
        int loadKernel(unsigned char *mem, unsigned int start_addr, unsigned int kern_size, unsigned int tx_addr);
        
        /** Load the subject matrix. */
        int loadSubject(unsigned char *mem, unsigned int start_addr, unsigned int subj_rows, unsigned int subj_cols, unsigned int tx_addr, unsigned int out_addr);
        
        /** Transmit a 64-bit packet. */
        virtual bool transmit64bitPacket(uint64 packet) = 0;

    private:
    
        mat_mult_cmd _cmd;

};

#endif // MAT_MULT_IF_H
