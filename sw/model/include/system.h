
#include <string>
#include <iostream>
#include <stdio.h>

#ifndef SYSTEM_H
#define SYSTEM_H

// ======================
// ===== PARAMETERS =====
// ======================

#define PIXEL_SIZE 1 // pixel size in bytes

// matrix dimensions
#define MAT_ROWS 1080
#define MAT_COLS 1920
#define MAT_SIZE (MAT_ROWS*MAT_COLS)

// kernel dimensions
#define MAX_KERN_DIM 7
#define MAX_KERN_ROWS MAX_KERN_DIM
#define MAX_KERN_SIZE (MAX_KERN_ROWS*MAX_KERN_ROWS)
#define KERN_SIZE_ROUNDED ((((MAX_KERN_SIZE) >> 3) + 1) << 3)

// CPU memory constraint
#define MEM_SIZE (1 << (20+4)) // 24MB
#define MAT_SIZE_PADDED ((MAT_ROWS+(MAX_KERN_DIM>>1))*MAT_COLS)

// CPU memory addresses
#define MAT_ADDR    0
#define KERN_ADDR   MAT_ADDR+MAT_SIZE_PADDED
#define OUT_ADDR    KERN_ADDR+KERN_SIZE_ROUNDED
#define UNUSED_ADDR OUT_ADDR+MAT_SIZE
#define BUILD_MAT_ADDR(r, c) (MAT_ADDR) + ((r) * MAT_COLS) + c
#define BUILD_KERN_ADDR(i)   (KERN_ADDR) + i
#define BUILD_OUT_ADDR(r, c) (OUT_ADDR) + ((r) * MAT_COLS) + c

// optimization parameter constraints
#define MAX_N_CLUSTERS 8
#define MAX_N_CORES_PER_CLUSTER MAX_KERN_DIM
#define PACKET_BYTES (sizeof(uint64_t) / PIXEL_SIZE)
#define MAX_CLUSTER_INPUT_SIZE (PACKET_BYTES + MAX_KERN_DIM - 1)

// ==================================
// ===== SIMULATION TIME MACROS =====
// ==================================

// clock period definitions
#define CC_CORE_NS 4.0    // compute core clock 250 MHz => 4ns
#define CC_MAIN_NS 15.625 // AXI bus clock 64 MHz => 15.625ns
#define CC_PROC_NS 10.0   // process host clock 100 MHz => 10ns
#define CC_PROC_PS 10000  // process host clock 100 MHz => 10000ps

// clock cycle calculations
#define CC_CORE(n) (n * CC_CORE_NS)
#define CC_MAIN(n) (n * CC_MAIN_NS)
#define CC_PROC(n) (n * CC_PROC_NS)

// wait for the next rising edge
#define POS_CORE() wait(CC_CORE_NS, SC_NS)
#define POS_MAIN() wait(CC_MAIN_NS, SC_NS)
#define POS_PROC() wait(CC_PROC_NS, SC_NS)
// yield so all modules can capture the rising edge signals
#define YIELD() wait(0, SC_NS)

// ========================================
// ===== UTILITY FUNCTIONS AND MACROS =====
// ========================================

// logging functions
#define LOG(a) std::cout << sc_time_stamp() << " - " << a << std::endl;
#define LOGF(a, ...) std::cout << sc_time_stamp() << " - "; printf(a, __VA_ARGS__); printf("\n")

#ifdef DO_DEBUG
    #define DEBUG(a) std::cout << sc_time_stamp() << " - " << a << std::endl;
    #define DEBUGF(a, ...) std::cout << sc_time_stamp() << " - "; printf(a, __VA_ARGS__); printf("\n")
#else
    #define DEBUG(a)
    #define DEBUGF(a, ...)
#endif

// parse command line arguments
bool parseCmdLine(int argc, char **argv, unsigned char *mem, int *kernelsize);

// visualize and output current memory
bool memoryWrite(char **argv, unsigned char *mem);
void memoryPrint(unsigned char *mem, int kernel_size);
bool writeOutput(char **argv, unsigned char *mem);
void printMat(unsigned char *mem, int mat_n_cols, int base_addr, int r, int c, int n_r, int n_c);

#endif // SYSTEM_H
