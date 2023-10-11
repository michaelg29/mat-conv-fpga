/*
 * bsp_api.c
 *
 *  Created on: September 28, 2023
 *      Author: Jacoby
 */

#include "bsp_api.h"





/**
  * @brief  Configure the module.
  * @note   This function abstracts
  * 	    the header information for the transaction.
  *
  * @param  regs  Configuration values for the registers
  *
  * @retval None
  */
void moduleConfig(apb_ctrl_registers_t regs){
}


/**
  * @brief  Poll the state of the module by reading the status registers.
  * @note   This function abstracts the header information for the transaction.
  *
  * @param  None
  *
  * @retval An apb_state_registers_t struct that contains the
  *	    value of the status registers.
  */
apb_state_registers_t moduleGetState(void){
}


/**
  * @brief  Send a kernel to the module.
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  * 	    the header information for the transaction.
  *
  * @param  addr  	Address of the kernel to be sent
  * @param  dimension  	The dimension (in pixels) of the row or column of the kernel sent 
  *			(assumed to be a square matrix).
  * @param  ordering	Specifies if the image is row major (=0) or column major (=1).
  *  
  * @retval The function returns an error code (if 0 -> no error. if <0 -> error). TODO specify more error codes
  */
int8_t sendKernel(uint32_t addr, uint32_t dimension, uint8_t ordering){
}


/**
  * @brief  Send an image to the module.
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  * 	    the header information for the transaction.
  *
  * @param  addr  	Address of the image to be sent
  * @param  size  	The size (in pixels) of the image sent
  * @param  ordering	Specifies if the image is row major (=0) or column major (=1).
  *  
  * @retval The function returns an error code (if 0 -> no error. if <0 -> error). TODO specify more error codes
  */
int8_t  sendImage(uint32_t addr, uint32_t size, uint8_t ordering){
}


/**
  * @brief  Send a command to the module.
  * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
  * 	    the header information for the transaction.
  *
  * @param  com  Command number from command enum
  *  
  * @retval None
  */
int8_t sendCommand(commands_e com){
}


/**
  * @brief  Register the callback for the reception of data.
  * @note   This function assumes that the module has been initialized with "moduleConfig".
  *	    If a NULL callback is registered, a dummy function is provided instead (but NULL
  *	    is returned if the dummy function was the previous callback).
  *
  * @param  cb  The callback funtion.
  *  
  * @retval The function returns the previous callback that was assigned.
  */
rx_callback_t registerCallback(rx_callback_t cb){
}



