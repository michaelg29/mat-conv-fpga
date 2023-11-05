
#include "systemc.h"

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
#define GET_CMD_OUT_ADDR(cmd) (cmd.command & 0x3FFFFFFF) << 3

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

#define CMP_CMD_ACK(cmd, ack) ((cmd.s_key == ack.s_key) && (cmd.command == ack.command) && (cmd.size == ack.size) && (cmd.tx_addr == ack.tx_addr) && (cmd.trans_id == ack.trans_id) && (cmd.e_key == ack.e_key))

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

#define ADDR_MASK      0x3F
#define OFFSET_COMMAND 0x00
#define OFFSET_PAYLOAD 0x20
#define SIZE_COMMAND   0x20
#define SIZE_PAYLOAD   0x20 // wrapped size

/**
 * Interface with the matrix multiplier module to issue commands.
 */
class mat_mult_if : virtual public sc_interface {

    public:

        // constructor
        mat_mult_if();
        
        int sendCmd(uint8_t *ext_mem, unsigned int cmd_type, unsigned int rows, unsigned int cols, unsigned int tx_addr, unsigned int out_addr);
        
        int sendPayload(uint8_t *ext_mem, unsigned int start_addr, unsigned int rows, unsigned int cols);

        /** Total reset. */
        void reset();

    protected:

        /** Register collection. */
        mat_mult_reg_t regs;

        /** Receive a 64-bit packet on the module. */
        virtual bool receive64bitPacket(uint64_t addr, uint64_t packet) = 0;

        /** Subclass resets. */
        virtual void protected_reset() = 0;

    private:

        /** Variables to write to the module. */
        uint32_t _cur_trans_id;
        mat_mult_cmd_t _cmd;
        mat_mult_ack_t _ack;
        uint64_t *_packets;

        /** Reset the module. */
        void private_reset();

};

#endif // MAT_MULT_IF_H
