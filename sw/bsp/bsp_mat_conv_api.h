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
 *  This is the BSP API to interface with the FPGA matrix convolution module.
 *
 *  A typical interaction between the CPU and the FPGA module is as follow:
 *  1-The CPU configures the FPGA module through the APB interface registers
 *  2-The CPU send a computation request to the FPGA module.
 *  The header then specifies:
 *  -The address in DDR4 memory where to store the result image
 *  -The size of the size of the image and/or the kernel
 *  The data contains the image and/or the kernel
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


#ifndef BSP_MAT_CONV_API_H_
#define BSP_MAT_CONV_API_H_

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#include "stdint.h"

/** Configuration macros. */
#define S_KEY_DEFAULT 0xCAFECAFE
#define E_KEY_DEFAULT 0xDEADBEEF
#define MAX_KERNEL_SIZE 5

/** Address macros. */
#define AXI3_DATA_OFFSET   0x00000000
#define AXI3_CMD_OFFSET    0x00000080
#define APB_REGSTAT_OFFSET 0x00000000
#define APB_REGCTRL_OFFSET 0x

typedef void (*rx_callback_t)(void);

/** Command type. */
typedef enum {
    LOAD_KERNEL = 0,
    LOAD_MATRIX = 1
} command_type_e;

/** Possible status values. */
typedef enum {
    STAT_OKAY     = 0x00000000,
    STAT_ERR_PROC = 0x00000001,
    STAT_ERR_KEY  = 0x00000002,
    STAT_ERR_SIZE = 0x00000004,
    STAT_ERR_CKSM = 0x00000008,
    STAT_ERR_OTH  = 0x00000010,
} status_e;

/** Readable state. */
typedef struct {

    /**
     * State register.
     * [ 4: 0] Status value, combination of bits in status_e.
     * [12: 5] Current number of columns the module is waiting to receive in the current row.
     * [31:13] Current number of packets the module is waiting to receive in the current subject.
     */
    uint32_t state_reg;

} apb_state_registers_t;

/** Writeable state. */
typedef struct {

    uint32_t reg1;
    //TODO describe the equivalent of a record type for control here

} apb_ctrl_registers_t;

/** Module information. */
typedef struct {

    uint32_t addr_axi; // address of the module in the FPGA AXI3 address space
    uint32_t addr_apb; // address of the module in the FPGA APB address space

} module_t;

/** Command header structure. */
typedef struct {

    uint32_t S_KEY;    // header start key
    uint32_t COMMAND;  // command to execute
    uint32_t SIZE;     // size of the input matrix
    uint32_t TX_ADDR;  // address to send the response packet
    uint32_t TRANS_ID; // transaction ID
    uint32_t STATUS;   // status
    uint32_t E_KEY ;   // header end key
    uint32_t CHKSUM;   // header checksum

} header_t;

/**
 * @brief  Set the module configuration values for the software program.
 *
 * @param  mat_conv Configuration structure.
 *
 * @retval None.
 */
void set_mat_conv(mat_conv_module_t mat_conv);

/**
 * @brief  Configure the module.
 * @note   This function abstracts the header information for the transaction.
 *
 * @param  regs Configuration values for the registers.
 *
 * @retval None.
 */
void module_config(apb_ctrl_registers_t regs);

/**
 * @brief  Poll the state of the module by reading the status registers.
 * @note   This function abstracts the header information for the transaction.
 *
 * @param  None
 *
 * @retval An apb_state_registers_t struct that contains the
 *     value of the status registers.
 */
apb_state_registers_t get_module_state(void);

/**
 * @brief Synchronously send the kernel to the module.
 * @note   This function assumes that the module has been initialized with "moduleConfig". This function abstracts
 *         the header information for the transaction.
 *
 * @param  kern_signed Whether the kernel is signed (1) or unsigned (0).
 * @param  kern_addr   Address of the kernel to be sent
 * @param  kern_dim    The dimension (in pixels) of the row or column of the kernel sent
 *                     (assumed to be a square matrix).
 * @param  n_kern_pkts Number of 64-bit packets to send for the whole kernel.
 *
 * @retval The function returns an error code from status_e.
 */
uint32_t send_kernel(uint8_t kern_signed, uint32_t kern_addr, uint32_t kern_dim, uint32_t n_kern_pkts);

uint32_t sendKernel(uint32_t addr, uint32_t dimension);
uint32_t sendKernelAsync(uint32_t addr, uint32_t dimension);
uint32_t sendImage(uint32_t addr, uint32_t size);
uint32_t sendImageAsync(uint32_t addr, uint32_t rows, uint32_t cols, uint32_t outAddr);
int8_t sendCommand(command_type_e com);
rx_callback_t registerCallback(rx_callback_t cb);



#ifdef __cplusplus
}
#endif // __cplusplus

#endif // BSP_MAT_CONV_API_H_
