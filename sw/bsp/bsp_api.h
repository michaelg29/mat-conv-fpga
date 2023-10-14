/*
 * bsp_api.h
 *
 *  Created on: September 28, 2023
 *      Author: Jacoby
 * 
 *  Modified: October 13, 2023
 *      Author: Frederik Martin
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
	LOAD_KERNEL = 0,
	LOAD_MATRIX = 1
}commands_e;

typedef enum{
	OK 					= 0x0,
	ERR 				= 0x1,
	ERR_SIZE_INVALID 	= 0x2,
	ERR_NO_KERNEL 		= 0x4,
	//0x8,
	//0x10,
	//0x20,
	//0x40,
	//0x80,
	ERR_CHECKSUM = 0x80000000;
} status_e;

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

typedef struct{

	uint32_t S_KEY; //Header start key 
	uint32_t COMMAND; //Command to execute  
	uint32_t SIZE; //Size of the input matrix 
	uint32_t TX_ADDR; //Address to send the response packet  
	uint32_t TRANS_ID; //Transaction ID 
	uint32_t STATUS; //STATUS
	uint32_t E_KEY ; //Header end key  
	uint32_t CHKSUM; //Header checksum 


} header_t; 


void moduleConfig(apb_ctrl_registers_t regs);
apb_state_registers_t moduleGetState(void);
uint32_t sendKernel(uint32_t addr, uint32_t dimension);
uint32_t sendKernelAsync(uint32_t addr, uint32_t dimension);
uint32_t sendImage(uint32_t addr, uint32_t size);
uint32_t sendImageAsync(uint32_t addr, uint32_t rows, uint32_t cols, uint32_t outAddr);
int8_t sendCommand(commands_e com);
rx_callback_t registerCallback(rx_callback_t cb);



#ifdef __cplusplus
}
#endif