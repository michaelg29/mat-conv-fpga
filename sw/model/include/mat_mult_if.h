
#include "systemc.h"
#include "mem_if.h"

#ifndef MAT_MULT_IF_H
#define MAT_MULT_IF_H

// ==========================
// ===== COMMAND FORMAT =====
// ==========================

// status values
#define MM_STAT_OKAY      0x00000000
#define MM_STAT_ERR_OTHER 0x00000001
#define MM_STAT_ERR_REQ   0x00000002
#define MM_STAT_ERR_KEY   0x00000004
#define MM_STAT_ERR_ORD   0x00000008
#define MM_STAT_ERR_SIZE  0x00000010
#define MM_STAT_ERR_CHKSM 0x00000020

// start and end keys
#define MM_S_KEY 0xCAFECAFE
#define MM_E_KEY 0xDEADBEEF

// command field values
#define MM_CMD_KERN 0x0
#define MM_CMD_SUBJ 0x1
#define GET_CMD_TYPE(cmd) ((cmd.command >> 30) & 0x1)
#define GET_CMD_OUT_ADDR(cmd) (cmd.command & 0x3FFFFFFF)

// size field values
#define GET_CMD_SIZE_ROWS(cmd) ((cmd.size >> 16) & 0xFFFF)
#define GET_CMD_SIZE_COLS(cmd) ((cmd.size >> 0) & 0xFFFF)

// calculate the checksum of a command packet
#define CALC_CMD_CHKSUM(cmd) \
    cmd.s_key ^ cmd.command ^ cmd.size ^ cmd.tx_addr ^ cmd.trans_id ^ cmd.reserved ^ cmd.e_key

// calculate the checksum of an acknowledge packet
#define CALC_ACK_CHKSUM(cmd) \
    cmd.s_key ^ cmd.command ^ cmd.size ^ cmd.tx_addr ^ cmd.trans_id ^ cmd.status ^ cmd.e_key

struct mat_mult_cmd_t {
    uint32_t s_key;
    uint32_t command;
    uint32_t size;
    uint32_t tx_addr;
    uint32_t trans_id;
    uint32_t reserved;
    uint32_t e_key;
    uint32_t chksum;
};

struct mat_mult_ack_t {
    uint32_t s_key;
    uint32_t command;
    uint32_t size;
    uint32_t tx_addr;
    uint32_t trans_id;
    uint32_t status;
    uint32_t e_key;
    uint32_t chksum;
};

#define N_PACKETS_IN_CMD sizeof(mat_mult_cmd_t) / sizeof(uint64_t)

// ================================
// ===== REGISTER DEFINITIONS =====
// ================================

struct mat_mult_reg_status_reg_t {
    uint8_t error;
    bool ready;
    bool multiplying;
};

struct mat_mult_reg_t {
    mat_mult_reg_status_reg_t status_reg;
};

// ================================
// ===== INTERFACE DEFINITION =====
// ================================

/**
 * Interface with the matrix multiplier module to issue commands.
 */
class mat_mult_if : public sc_module, virtual public sc_interface {

    public:

        // constructor
        mat_mult_if(sc_module_name name, uint8_t *ext_mem);
        
        int sendCmd(unsigned int cmd_type, unsigned int rows, unsigned int cols, unsigned int tx_addr, unsigned int out_addr);
        
        int sendPayload(unsigned int start_addr, unsigned int rows, unsigned int cols);

        /** Command to load kernel. */
        int loadKernelCmd(unsigned int kern_size, unsigned int tx_addr);
        
        /** Load kernel in payload. */
        int loadKernelPayload(unsigned int start_addr, unsigned int kern_size);

        /** Command to load subject. */
        int loadSubjectCmd(unsigned int subj_rows, unsigned int subj_cols, unsigned int tx_addr, unsigned int out_addr);
        
        /** Load subject in payload. */
        int loadSubjectPayload(unsigned int start_addr, unsigned int subj_rows, unsigned int subj_cols);

        /** Total reset. */
        void reset();

    protected:

        /** Register collection. */
        mat_mult_reg_t regs;

        /** Transmit a 64-bit packet to the module. */
        virtual bool transmit64bitPacket(uint64_t addr, uint64_t packet) = 0;

        /** Subclass resets. */
        virtual void protected_reset() = 0;

    private:
    
        /** Memory containing data and ack packets. */
        uint8_t *_ext_mem;

        /** Variables to write to the module. */
        uint32_t _cur_trans_id;
        mat_mult_cmd_t _cmd;
        mat_mult_ack_t _ack;

        /** Reset the module. */
        void private_reset();

};

#endif // MAT_MULT_IF_H
