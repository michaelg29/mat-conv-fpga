/*
 * bsp_api.c
 *
 *  Created on: September 28, 2023
 *      Author: Jacoby
 *
 *    Modified: October 13, 2023
 *      Author: Frederik Martin
 */

#include "bsp_api.h"

/** Placeholder for interrupt callback. */
void dummy() {}
rx_callback_t callback = &dummy;

/** Runtime variables. */
mat_conv_module_t _mat_conv;
uint32_t trans_id = 0xFFFFFFFF;

/**
 * @brief Gets the next transaction ID.
 * @note Increments the current trans_id and prevents it from overflowing to 0.
 *
 *
 * @retval Next trans_id.
*/
uint32_t getNextTransID(){
  trans_id +=2; //by starting with an odd value and always incrementing by 2, the value will never equal zero even when overflowing
  return trans_id;
}

/**
 * @brief Calculates the checksum of a header.
 *
 * @retval Checksum of the header.
*/
uint32_t calc_chksum(header_t h){
  return h.S_KEY    ^
         h.COMMAND  ^
         h.SIZE     ^
         h.TX_ADDR  ^
         h.TRANS_ID ^
         h.STATUS   ^
         h.E_KEY;
}

void set_mat_conv(mat_conv_module_t mat_conv) {
    _mat_conv = mat_conv;
}

void module_config(apb_ctrl_registers_t regs) {
    apb_ctrl_registers_t* ctrl_regs = (apb_ctrl_registers_t*)(_mat_conv.addr_apb + APB_REGCTRL_OFFSET);
    (*ctrl_regs) = regs;
}

apb_state_registers_t get_module_state(void) {
    apb_state_registers_t* state_regs = (apb_state_registers_t*)(_mat_conv.addr_apb + APB_REGSTAT_OFFSET);
    return *state_regs;
}

uint32_t send_kernel(uint8_t kern_signed, uint32_t kern_addr, uint32_t kern_dim, uint32_t n_kern_pkts) {
    if (kern_dim > MAX_KERNEL_SIZE) {
        return STAT_ERR_SIZE;
    }

    // construct header and ack packets
    header_t header, ack;
    header.S_KEY    = S_KEY_DEFAULT;
    header.COMMAND  = ((kern_signed & 1) << 31) |
                      ((LOAD_KERNEL & 1) << 30);
    header.SIZE     = ((n_kern_pkts & 0x3fff) << 16) |
                      ((kern_dim & 0x7ff) << 4) |
                      ((kern_dim & 0xf) << 0);
    header.TX_ADDR  = &ack;
    header.TRANS_ID = getNextTransID();
    header.STATUS   = 0; // reserved
    header.E_KEY    = E_KEY_DEFAULT;
    header.CHKSUM   = calc_chksum(header);

    // TODO: write to module
    // axi_write(_mat_conv.addr_axi + AXI3_CMD_OFFSET, &header, sizeof(header_t));
    // axi_write(_mat_conv.addr_axi + AXI3_DATA_OFFSET, (void*)kern_addr, n_kern_pkts);

    uint32_t error;
    if (ack.CHKSUM != calc_chksum(ack)){
        error = STAT_ERR_CKSM;
    }
    else {
        error = ack.STATUS;
    }

    return error;
}

uint32_t send_kernel_async(uint8_t kern_signed, uint32_t kern_addr, uint32_t kern_dim, uint32_t n_kern_pkts, header_t *ack_ptr) {
    if (kern_dim > MAX_KERNEL_SIZE) {
        return STAT_ERR_SIZE;
    }

    // construct header packet
    header_t header;
    header.S_KEY    = S_KEY_DEFAULT;
    header.COMMAND  = ((kern_signed & 1) << 31) |
                      ((LOAD_KERNEL & 1) << 30);
    header.SIZE     = ((n_kern_pkts & 0x3fff) << 16) |
                      ((kern_dim & 0x7ff) << 4) |
                      ((kern_dim & 0xf) << 0);
    header.TX_ADDR  = ack_ptr;
    header.TRANS_ID = getNextTransID();
    header.STATUS   = 0; // reserved
    header.E_KEY    = E_KEY_DEFAULT;
    header.CHKSUM   = calc_chksum(header);

    // TODO: write to module
    // axi_write(_mat_conv.addr_axi + AXI3_CMD_OFFSET, &header, sizeof(header_t));

    // TODO: DMA
    //DMA_TCDn_SADDR = addr;
    //DMA_TCDn_ATTR |= (0b011) << 8 || 0b011; 64 bit transfers
    //DMA_TCDn_SOFF |= 8; // 64b=8B transfers
    //DMA_TCDn_SLAST = -n_kern_pkts << 3;
    //DMA_TCDn_DADDR = _mat_conv.addr_axi + AXI3_DATA_OFFSET;
    //DMA_TCDn_NBYTES = n_kern_pkts << 3;
    //DMA_TCDn_CITER = 1;
    //DMA_TCDn_BITER = 1;
    //DMA_TCDn_DOFF = 0;
    //DMA_TCDn_CSR |= (0b11<<14);

    uint32_t error;
    if (ack.CHKSUM != calc_chksum(ack)){
        error = STAT_ERR_CKSM;
    }
    else {
        error = ack.STATUS;
    }

    return error;
}

uint32_t send_subject(uint8_t kern_signed, uint32_t kern_addr, uint32_t kern_dim, uint32_t n_kern_pkts) {
    if (kern_dim > MAX_KERNEL_SIZE) {
        return STAT_ERR_SIZE;
    }

    // construct header packet
    header_t header;
    header.S_KEY    = S_KEY_DEFAULT;
    header.COMMAND  = ((LOAD_SUBJECT & 1) << 30) |
                      ((out_addr >> 2) << 0);
    header.SIZE     = (((n_subj_pkts >> 7) & 0x3fff) << 16) |
                      ((subj_rows & 0x7ff) << 4) |
                      (((subj_cols >> 7) & 0xf) << 0);
    header.TX_ADDR  = ack_ptr;
    header.TRANS_ID = getNextTransID();
    header.STATUS   = 0; // reserved
    header.E_KEY    = E_KEY_DEFAULT;
    header.CHKSUM   = calc_chksum(header);

    // TODO: write to module
    // axi_write(_mat_conv.addr_axi + AXI3_CMD_OFFSET, &header, sizeof(header_t));
    // axi_write(_mat_conv.addr_axi + AXI3_DATA_OFFSET, (void*)kern_addr, n_kern_pkts);

    uint32_t error;
    if (ack.CHKSUM != calc_chksum(ack)){
        error = STAT_ERR_CKSM;
    }
    else {
        error = ack.STATUS;
    }

    return error;
}

uint32_t send_subject_async(uint32_t subj_addr, uint32_t subj_rows, uint32_t subj_cols, uint32_t n_subj_pkts, uint32_t out_addr, header_t *ack_ptr) {

    // construct header packet
    header_t header;
    header.S_KEY    = S_KEY_DEFAULT;
    header.COMMAND  = ((LOAD_SUBJECT & 1) << 30) |
                      ((out_addr >> 2) << 0);
    header.SIZE     = (((n_subj_pkts >> 7) & 0x3fff) << 16) |
                      ((subj_rows & 0x7ff) << 4) |
                      (((subj_cols >> 7) & 0xf) << 0);
    header.TX_ADDR  = ack_ptr;
    header.TRANS_ID = getNextTransID();
    header.STATUS   = 0; // reserved
    header.E_KEY    = E_KEY_DEFAULT;
    header.CHKSUM   = calc_chksum(header);

    // TODO: write to module
    // axi_write(_mat_conv.addr_axi + AXI3_CMD_OFFSET, &header, sizeof(header_t));

    // TODO: DMA
    //DMA_TCDn_SADDR = subj_addr;
    //DMA_TCDn_ATTR |= (0b011) << 8 || 0b011; 64 bit transfers
    //DMA_TCDn_SOFF |= 8; // 64b=8B transfers
    //DMA_TCDn_SLAST = -n_subj_pkts << 3;
    //DMA_TCDn_DADDR = _mat_conv.addr_axi + AXI3_DATA_OFFSET;
    //DMA_TCDn_NBYTES = n_subj_pkts << 3;
    //DMA_TCDn_CITER = 1;
    //DMA_TCDn_BITER = 1;
    //DMA_TCDn_DOFF = 0;
    //DMA_TCDn_CSR |= (0b11<<14);

    uint32_t error;
    if (ack.CHKSUM != calc_chksum(ack)){
        error = STAT_ERR_CKSM;
    }
    else {
        error = ack.STATUS;
    }

    return error;
}

rx_callback_t register_callback(rx_callback_t cb){

    rx_callback_t oldCB = callback;

    if(cb == NULL){
        callback = &dummy;
    }
    else{
        callback = cb;
    }

    if(oldCB == &dummy){
        return NULL;
    }
    else{
        return oldCB;
    }
}




