
#include "systemc.h"
#include "system.h"
#include "mat_mult_if.h"

#ifndef MAT_MULT_H
#define MAT_MULT_H

enum mat_mult_state_t {
    WAIT_CMD_KERN_SKEY, // waiting for s_key and command fields for kernel
    WAIT_CMD_SUBJ_SKEY, // waiting for s_key and command fields for subject
    WAIT_CMD_SIZE,      // waiting for size and tx_addr fields
    WAIT_CMD_TID,       // waiting for trans_id and reserved fields
    WAIT_CMD_EKEY,      // waiting for e_key and chksum fields
    WAIT_DATA,          // waiting for all data to be received
    PROCESSING          // processing
};

class mat_mult : public mat_mult_if {
    
    public:
    
        sc_port<mem_if> memIf;

        mat_mult(sc_module_name name, uint8_t *ext_mem);

    private:
    
        // state variables
        mat_mult_state_t _cur_state;
        uint64_t *_cur_ptr;
        uint32_t _expected_el;
        uint32_t _loaded_el;
        
        // command and ack buffers
        mat_mult_cmd_t _cur_cmd;
        mat_mult_ack_t _cur_ack;
        
        // internal memories
        uint8_t kern_mem[KERN_SIZE_ROUNDED];
        uint8_t subj_mem[MAT_SIZE];
        
        bool transmit64bitPacket(uint64_t addr, uint64_t packet);
        void protected_reset();

};

#endif // MAT_MULT_H
