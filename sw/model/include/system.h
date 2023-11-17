
#include <string>

#ifndef SYSTEM_H
#define SYSTEM_H

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

// CPU memory addresses
#define MAT_ADDR    0
#define KERN_ADDR   MAT_ADDR+MAT_SIZE
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

bool parseCmdLine(int argc, char **argv, unsigned char *mem, int *kernelsize);
bool memoryWrite(char **argv, unsigned char *mem);
bool writeOutput(char **argv, unsigned char *mem);

void printMat(unsigned char *mem, int mat_n_cols, int base_addr, int r, int c, int n_r, int n_c);
void memoryPrint(unsigned char *mem, int kernel_size);

#endif // SYSTEM_H
