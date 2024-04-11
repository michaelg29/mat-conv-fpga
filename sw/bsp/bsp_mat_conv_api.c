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
    header_t header, ACK;
    header.S_KEY    = S_KEY_DEFAULT;
    header.COMMAND  = ((kern_signed & 1) << 31) |
                      ((LOAD_KERNEL & 1) << 30);
    header.SIZE     = ((n_kern_pkts & 0x3fff) << 16) |
                      ((kern_dim & 0x7ff) << 4) |
                      ((kern_dim & 0xf) << 0);
    header.TX_ADDR  = &ACK;
    header.TRANS_ID = getNextTransID();
    header.STATUS   = 0; // reserved
    header.E_KEY    = E_KEY_DEFAULT;
    header.CHKSUM   = calc_chksum(header);
}

/**
  * @brief  Send a kernel to the module.
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  *         the header information for the transaction.
  *
  * @param  addr    Address of the kernel to be sent
  * @param  dimension   The dimension (in pixels) of the row or column of the kernel sent
  *         (assumed to be a square matrix).
  *
  * @retval The function returns an error code (if 0 -> no error. if > 0 -> error). TODO specify more error codes
  */
int32_t sendKernel(uint32_t addr, uint32_t dimension){

  if(dimension > MAX_KERNEL_SIZE){
    return ERR_SIZE;
  }

  header_t header, ACK;
  header.S_KEY = S_KEY_DEFAULT;
  header.COMMAND = LOAD_KERNEL;
  header.SIZE = (dimension<<16) | (0xFFFF & dimension);
  header.TX_ADDR = &ACK;
  header.TRANS_ID = getNextTransID();
  header.STATUS = 0; //reserved
  header.E_KEY = E_KEY_DEFAULT;
  header.CHKSUM = calc_chksum(header);

  //writeTO(MODULE_AXI_SLV_ADDR, header, sizeof(header));
  //writeTO(MODULE_AXI_SLV_ADDR, addr, dimension*dimension);

  //todo more robust error checks
  int8_t error;
  if(ACK.CHKSUM != calc_chksum(ACK)){
    error = ERR_CHKSM;
  }
  else {
    error = ACK.STATUS;
  }

  return error;

}

/**
  * @brief  Send a kernel to the module using DMA. Non-blocking version of "sendKernel".
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  *         the header information for the transaction.
  *
  * @param  addr    Address of the kernel to be sent
  * @param  dimension   The dimension (in pixels) of the row or column of the kernel sent
  *         (assumed to be a square matrix).
  *
  * @retval The function returns an error code (if 0 -> no error. if > 0 -> error). TODO specify more error codes
  */
int32_t sendKernelAsync(uint32_t addr, uint32_t dimension) {

  if (dimension > MAX_KERNEL_SIZE){
    return ERR_SIZE;
  }

  header_t header, ACK;
  header.S_KEY = S_KEY_DEFAULT;
  header.COMMAND = LOAD_KERNEL;
  header.SIZE = (dimension<<16) | (0xFFFF & dimension);
  header.TX_ADDR = &ACK;
  header.TRANS_ID = getNextTransID();
  header.STATUS = 0; //reserved
  header.E_KEY = E_KEY_DEFAULT;
  header.CHKSUM = calc_chksum(header);

  //writeTO(MODULE_AXI_SLV_ADDR, header, sizeof(header));

  //DMA_TCDn_SADDR = addr;

  //DMA_TCDn_ATTR |= (0b011) << 8 || 0b011; 64 bit transfers

  //DMA_TCDn_SOFF |= 8; //64 bit transfers, 8 bytes

  //DMA_TCDn_SLAST = -dimension*dimension;

  //DMA_TCDn_DADDR = MODULE_AXI_SLV_ADDR;

  //DMA_TCDn_NBYTES = dimension*dimension;

  //DMA_TCDn_CITER = 1;
  //DMA_TCDn_BITER = 1;

  //DMA_TCDn_DOFF = 0;

  //DMA_TCDn_CSR |= (0b11<<14);


  //todo more robust error checks
  int32_t error;
  if(ACK.CHKSUM != calc_chksum(ACK)){
    error = ERR_CHKSM;
  }
  else {
    error = ACK.STATUS;
  }

  return error;

}


/**
  * @brief  Send an image to the module.
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  *         the header information for the transaction.
  *
  * @param  addr    Address of the image to be sent
  * @param  size    The size (in pixels) of the image sent
  *
  * @retval The function returns an error code (if 0 -> no error. if > 0 -> error). TODO specify more error codes
  */
int32_t sendImage(uint32_t addr, uint32_t rows, uint32_t cols, uint32_t outAddr) {

  header_t header, ACK;
  header.S_KEY = S_KEY_DEFAULT;
  header.COMMAND = (LOAD_MATRIX << 30) | (outAddr >> 2);
  header.SIZE = (rows<<16) | (0xFFFF & cols);
  header.TX_ADDR = &ACK;
  header.TRANS_ID = getNextTransID();
  header.STATUS = 0; //reserved
  header.E_KEY = E_KEY_DEFAULT;
  header.CHKSUM = calc_chksum(header);

  //writeTO(MODULE_AXI_SLV_ADDR, header, sizeof(header));
  //writeTO(MODULE_AXI_SLV_ADDR, addr, rows*cols);

  //todo more robust error checks
  int32_t error;
  if(ACK.CHKSUM != calc_chksum(ACK)){
    error = ERR_CHKSM;
  }
  else {
    error = ACK.STATUS;
  }

  return error;
}


/**
  * @brief  Send an image to the module using DMA. Non-blocking version of "sendImage".
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  *         the header information for the transaction.
  *
  * @param  addr    Address of the image to be sent
  * @param  size    The size (in pixels) of the image sent
  *
  * @retval The function returns an error code (if 0 -> no error. if > 0 -> error). TODO specify more error codes
  */
int32_t sendImageAsync(uint32_t addr, uint32_t rows, uint32_t cols, uint32_t outAddr){


  header_t header, ACK;
  header.S_KEY = S_KEY_DEFAULT;
  header.COMMAND = (LOAD_MATRIX << 30) | (0x3fffffff & outAddr);
  header.SIZE = (rows<<16) | (0xFFFF & cols);
  header.TX_ADDR = &ACK;
  header.TRANS_ID = getNextTransID();
  header.STATUS = 0; //reserved
  header.E_KEY = E_KEY_DEFAULT;
  header.CHKSUM = calc_chksum(header);

  //writeTO(MODULE_AXI_SLV_ADDR, header, sizeof(header));

  //DMA_TCDn_SADDR = addr;

  //DMA_TCDn_ATTR |= (0b011) << 8 || 0b011; 64 bit transfers

  //DMA_TCDn_SOFF |= 8; //64 bit transfers, 8 bytes

  //DMA_TCDn_SLAST = -size;

  //DMA_TCDn_DADDR = MODULE_AXI_SLV_ADDR;

  //DMA_TCDn_NBYTES = size;

  //DMA_TCDn_CITER = 1;
  //DMA_TCDn_BITER = 1;

  //DMA_TCDn_DOFF = 0;

  //DMA_TCDn_CSR |= (0b11<<14);


  //todo more robust error checks
  int32_t error;
  if(ACK.CHKSUM != calc_chksum(ACK)){
    error = ERR_CHKSM;
  }
  else {
    error = ACK.STATUS;
  }

  return error;
}




/**
  * @brief  Send a command to the module.
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  *         the header information for the transaction.
  *
  * @param  com  Command number from command enum
  *
  * @retval None
  */
int8_t sendCommand(command_type_e com){



}


/**
  * @brief  Register the callback for the reception of data.
  * @note   This function assumes that the module has been initialized with "moduleConfig".
  *     If a NULL callback is registered, a dummy function is provided instead (but NULL
  *     is returned if the dummy function was the previous callback).
  *
  * @param  cb  The callback funtion.
  *
  * @retval The function returns the previous callback that was assigned.
  */
rx_callback_t registerCallback(rx_callback_t cb){

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




