
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
#define GET_CMD_SIZE_COLS(cmd) ((cmd.size >>  0) & 0xF)
#define GET_CMD_SIZE_NELS(cmd) ((cmd.size >> 15) & 0x1FFFF)
#define GET_CMD_SIZE_ROWS(cmd) ((cmd.size >>  4) & 0x7FF)
#define GET_CMD_SIZE_SUBJ_COLS(cmd) ((GET_CMD_SIZE_COLS(cmd)) << 7)
#define GET_CMD_SIZE_SUBJ_NELS(cmd) ((GET_CMD_SIZE_NELS(cmd)) << 7)
#define GET_CMD_SIZE_SUBJ_ROWS(cmd) (GET_CMD_SIZE_ROWS(cmd))

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

// ==========================================
// ===== REGISTER AND STATE DEFINITIONS =====
// ==========================================

/** Status register. */
struct mat_mult_reg_status_reg_t {
    uint8_t error;
    bool ready;
};

/** Current command type register. */
struct mat_mult_reg_cmd_type_reg_t {
    bool is_kern;
    bool is_subj;
};

/** Register collection. */
struct mat_mult_reg_t {
    mat_mult_reg_status_reg_t status_reg;
    mat_mult_reg_cmd_type_reg_t cmd_type_reg;
};

enum mat_mult_state_e {
    WAIT_CMD_SKEY, // waiting for s_key and command fields
    WAIT_CMD_SIZE, // waiting for size and tx_addr fields
    WAIT_CMD_TID,  // waiting for trans_id and reserved fields
    WAIT_CMD_EKEY, // waiting for e_key and chksum fields
    WAIT_DATA,     // waiting for data to be received
};

// ================================
// ===== INTERFACE DEFINITION =====
// ================================

#define ADDR_MASK      0xFF
#define OFFSET_PAYLOAD 0x00
#define OFFSET_COMMAND 0x80
#define SIZE_PAYLOAD   0x80 // wrapped size
#define SIZE_COMMAND   0x20

/**
 * Interface with the matrix multiplier module to issue commands.
 */
class mat_mult_if : virtual public sc_interface {

    public:

        /** Constructor. */
        mat_mult_if();

        /**
         * @brief Issue a command to the module to load a matrix.
         *
         * @param ext_mem  CPU memory which will eventually contain the acknowledge packet.
         * @param cmd_type `MM_CMD_KERN` or `MM_CMD_SUBJ`.
         * @param rows     Number of rows in the matrix.
         * @param cols     Number of columns in the matrix. Must be a multiple of 8.
         * @param tx_addr  Where to write the acknowledge packet.
         * @param out_addr Where to write the output matrix. Ignored for `MM_CMD_KERN`.
         * @param in_addr  The start address of the payload in ext_mem.
         */
        void send_cmd(uint8_t *ext_mem, unsigned int cmd_type, unsigned int rows, unsigned int cols, unsigned int tx_addr, unsigned int out_addr, unsigned int in_addr);

        /**
         * @brief Verify the acknowledge packet in `ext_mem` at `tx_addr`.
         *
         * @retval The status in the acknowledge packet.
         */
        int verify_ack(uint8_t *ext_mem, unsigned int tx_addr);

        /** Total reset. */
        void reset();

    protected:

        /** Receive a 64-bit `packet` on the module, addressed to `addr`. */
        virtual bool receive_packet(uint64_t addr, uint64_t packet) = 0;

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
