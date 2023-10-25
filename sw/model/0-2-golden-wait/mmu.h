
#include "systemc.h"
#include "system.h"
#include "core.h"
#include "mem_if.h"


#ifndef MMU_H
#define MMU_H

#define MAX_NUM_CORES (MAX_KERN_ROWS*MAX_KERN_ROWS)
#define ID(x, y) (x + y * _row_length)

class mmu : public sc_module {

    public:

        mmu(sc_module_name name, uint32_t n_cores = MAX_NUM_CORES, uint32_t row_length = MAT_COLS, uint32_t kernel_size = MAX_KERN_ROWS);

        void store(uint8_t nextVal);
        uint32_t compute_output();
        void protected_reset();

    private:
    
        sc_port<mem_if> _memIf;

        uint32_t _n_cores;
        core* _cores[MAX_NUM_CORES];


        uint32_t _store_counter=0;
        uint32_t _compute_row_index_counter=0;//counter to keep track of what memory adresses to load to compute the next result
        uint32_t _compute_col_index_counter=0;//counter to keep track of what memory adresses to load to compute the next result
        uint32_t _col_index_counter=0;//counter to keep track of whhen columns overflow

        uint32_t _row_length;
        uint32_t _col_length;
        uint32_t _kernel_size;

        bool _wait = 1; 

};

#endif // MMU_H
