
#include "system.h"
#include "sc_trace.hpp"

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <string>

void memoryRead(char *memfile, unsigned char *mem, unsigned int memout_size) {
    FILE *fp = fopen(memfile, "rb");

    unsigned int cursor = 0;
    if (fp) {
        // get file size
        fseek(fp, 0L, SEEK_END);
        int fsize = ftell(fp) - cursor;
        fseek(fp, cursor, SEEK_SET);

        int n = fsize > memout_size ? memout_size : fsize;
        cursor = fread(mem, 1, n, fp);
    }

    // pad with zeros
    if (cursor < memout_size) {
        memset(mem + cursor, 0, memout_size - cursor);
    }
}

bool parseCmdLine(int argc, char **argv, unsigned char *mem, int *kernelsize) {
    // check usage
    if (argc < 5 || argc > 7) {
    std::cerr << "Usage: " << argv[0] << " <INPUT_FILE> <OUTPUT_FILE> <KERNEL_FILE> <KERNEL_SIZE> [<DO_RANDOMIZE> [<TRACE_FILE>]]" << std::endl;
        return false;
    }

    // validate kernel size
    *kernelsize = std::stoi(argv[4]);
    if (*kernelsize > MAX_KERN_ROWS) {
        std::cerr << "*** ERROR in main: invalid KERNEL_SIZE, max is " << MAX_KERN_ROWS << std::endl;
        return false;
    }
    if (!(*kernelsize & 1)) {
        std::cerr << "*** ERROR in main: KERNEL_SIZE is not odd" << std::endl;
        return false;
    }

    // determine randomization
    if (argc >= 6 && argv[5][0] == '1') {
        printf("Randomizing\n");
        srand(time(0));
        for (int i = 0; i < MEM_SIZE; i++) {
            mem[i] = rand() & 0xff;
        }
    }
    else {
        // read memory
        memoryRead(argv[1], mem, MAT_SIZE); // load image
        memoryRead(argv[3], mem + KERN_ADDR, MAX_KERN_SIZE); // load kernel
    }

    // pad input matrix with zeros
    memset(mem + MAT_ADDR + MAT_SIZE, 0, MAT_SIZE_PADDED - MAT_SIZE);

    // enable or disable logging
    if (argc >= 7) {
        sc_tracer::enable();
        sc_tracer::init(argv[6], SC_NS);
    }
    else {
        sc_tracer::disable();
    }

    return true;
}

bool memoryWrite(char **argv, unsigned char *mem) {
    // write input file
    char *file = argv[1];
    FILE *fp = fopen(file, "wb");
    if (fp) {
        fwrite(mem + MAT_ADDR, 1, MAT_SIZE, fp);
        fclose(fp);
    }

    // write output file
    file = argv[2];
    fp = fopen(file, "wb");
    if (fp) {
        fwrite(mem + OUT_ADDR, 1, MAT_SIZE, fp);
        fclose(fp);
    }

    // write kernel file
    file = argv[3];
    fp = fopen(file, "wb");
    if (fp) {
        fwrite(mem + KERN_ADDR, 1, MAX_KERN_SIZE, fp);
        fclose(fp);
    }

    return true;
}

void printMat(unsigned char *mem, int mat_n_cols, int base_addr, int r, int c, int n_r, int n_c) {
#define ADDR(row, col) base_addr + (row) * mat_n_cols + (col)

    n_r += r;
    n_c += c;
    for (; r < n_r; r++) {
        printf("%04d: ", r);
        for (int c_i = c; c_i < n_c; c_i++) {
            printf("%02x ", (int)mem[ADDR(r, c_i)]);
        }
        printf("\n");
    }

#undef ADDR
}

#define MIN(a, b) a > b ? b : a

void memoryPrint(unsigned char *mem, int kernel_size) {
    std::cout << std::endl << "==========" << std::endl;
    std::cout << "Input matrix:" << std::endl;
    printMat(mem, MAT_COLS, MAT_ADDR, 0, 0, MIN(MAT_ROWS, 10), MIN(MAT_COLS, 20));

    std::cout << "Kernel:" << std::endl;
    printMat(mem, kernel_size, KERN_ADDR, 0, 0, kernel_size, kernel_size);

    std::cout << "Output matrix:" << std::endl;
    printMat(mem, MAT_COLS, OUT_ADDR, 0, 0, MIN(MAT_ROWS, 10), MIN(MAT_COLS, 20));
    std::cout << std::endl << "==========" << std::endl;
}
