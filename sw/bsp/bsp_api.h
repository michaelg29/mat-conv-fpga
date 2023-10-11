/*
 * bsp_api.h
 *
 *  Created on: September 28, 2023
 *      Author: Jacoby
 *
 * 
 *  Description:
 *  This is the BSP API to interface with the FPGA convolution module.
 *   
 *  A typical interaction between the CPU and the FPGA module is as follow:
 *  1-The CPU configures the FPGA module through the APB interface registers
 *  2-The CPU send a computation request to the FPGA module.
 *	The header then specifies:
 *	-The address in DDR4 memory where to store the result image
 *	-The size of the size of the image and/or the kernel
 *	The data contains the image and/or the kernel
 *  3-Once the computation is done, the FPGA module stores the result image
 *    at the address specified in the header. It then notifies the CPU
 *    through an interrupt
 *  4-The CPU can poll the status register of the FPGA module at any time.
 *    It can also send commands to the FPGA module (start/stop for example).
 *  
 *
 * 
 *   
 */


#ifndef BSP_API_H_
#define BSP_API_H_


#ifdef __cplusplus
extern "C" {
#endif

#include "stdint.h"

typedef void (*rx_callback_t)(void);

typedef enum{
	//TODO list commands
}commands_e;

typedef struct{

	uint32_t reg1;
	//TODO describe the equivalent of a record type for status here

} apb_state_registers_t; 


typedef struct{

	uint32_t reg1;
	//TODO describe the equivalent of a record type for control here

} apb_ctrl_registers_t; 

typedef struct{

	uint32_t addr; //Address of the module in the FPGA

} module_t; 



void moduleConfig(apb_ctrl_registers_t regs);
apb_state_registers_t moduleGetState(void);
int8_t sendKernel(uint32_t addr, uint32_t dimension);
int8_t sendImage(uint32_t addr, uint32_t size, uint8_t ordering);
int8_t sendCommand(commands_e com);
rx_callback_t registerCallback(rx_callback_t cb);



#ifdef __cplusplus
}
#endif