
#include "system.h"

#include "systemc.h"
#include <iostream>
#include <string>

int kernelsize;
int hf_kernelsize;
unsigned char memory[MEM_SIZE];

SC_MODULE(mmModule) {
    
    SC_CTOR(mmModule) {
        SC_THREAD(do_mat_mult);
    }
    
    unsigned char convolve(int r, int c) {
        if (r == 0 || c == 0 || r == MAT_ROWS-1 || c == MAT_COLS-1) {
            return 0;
        }
        
        int res = 0;
        
        int kerneli = 0;
        for (int i = -hf_kernelsize; i <= hf_kernelsize; i++) {
            for (int j = -hf_kernelsize; j <= hf_kernelsize; j++) {
                res += (int)(unsigned int)memory[BUILD_MAT_ADDR(r+i, c+j)] // matrix value is unsigned byte
                     * (int)(char)memory[BUILD_KERN_ADDR(kerneli)];        // kernel value is signed byte
                kerneli++;
            }
        }
        
        return (unsigned char)res;
    }
    
    void do_mat_mult() {
        for (int r = 0; r < MAT_ROWS; r++) {
            for (int c = 0; c < MAT_COLS; c++) {
                memory[BUILD_OUT_ADDR(r, c)] = convolve(r, c);
            }
        }
    }
    
}; // SC_MODULE(sadModule)

int sc_main(int argc, char* argv[]) {
    if (!parseCmdLine(argc, argv, memory, &kernelsize)) {
        return 1;
    }
    
    std::cout << "Matrix size: " << MAT_ROWS << "x" << MAT_COLS << ", kernel size: " << kernelsize << "x" << kernelsize << std::endl;
    hf_kernelsize = kernelsize >> 1;
    memoryPrint(memory, kernelsize);
    
    mmModule mm("MM");
    
    /* run the simulation */
    sc_time startTime = sc_time_stamp();
    sc_start();
    sc_time stopTime = sc_time_stamp();

    cout << "Simulated for " << (stopTime - startTime) << endl;
    
    memoryWrite(argv, memory);
    memoryPrint(memory, kernelsize);
    
    return 0;
}
