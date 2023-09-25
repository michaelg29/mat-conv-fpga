
#include <string>

#ifndef SYSTEM_H
#define SYSTEM_H

#define MAT_ROWS 1080
#define MAT_COLS 1920
#define MAT_SIZE MAT_ROWS*MAT_COLS

#define MAX_KERN_ROWS 7
#define MAX_KERN_SIZE (MAX_KERN_ROWS*MAX_KERN_ROWS)

#define MEM_SIZE MAT_SIZE+MAX_KERN_SIZE+MAT_SIZE

#define MAT_ADDR  0
#define KERN_ADDR 0+MAT_SIZE
#define OUT_ADDR  KERN_ADDR+MAX_KERN_SIZE

#define BUILD_MAT_ADDR(r, c) (MAT_ADDR) + ((r) * MAT_COLS) + c
#define BUILD_KERN_ADDR(i)   (KERN_ADDR) + i
#define BUILD_OUT_ADDR(r, c) (OUT_ADDR) + ((r) * MAT_COLS) + c

bool parseCmdLine(int argc, char **argv, unsigned char *mem, int *kernelsize);
bool memoryWrite(char **argv, unsigned char *mem);

void memoryPrint(unsigned char *mem, int kernelsize);

#endif // SYSTEM_H
