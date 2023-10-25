
#include "mmu.h"
#include "systemc.h"
#include "system.h"


mmu::mmu(sc_module_name name, uint32_t n_cores, uint32_t row_length, uint32_t kernel_size) 
        : sc_module(name), _n_cores(n_cores), _row_length(row_length), _kernel_size(kernel_size)
{
    
    for (int i = 0; i < _n_cores; ++i) {
        // initialize each core
        _cores[i] = new core(("core" + std::to_string(i)).c_str());
    }
}


void mmu::store(uint8_t nextVal) {
    //TODO store val in mem

    _memIf->write(_store_counter, nextVal);

    _store_counter += 1;
    if(_store_counter >= _row_length*_kernel_size) {
        _store_counter = 0;
    }
}

uint32_t mmu::compute_output() {
    if(_store_counter >= (_kernel_size*(1+_row_length>>1)-1)) {
        _wait = 0;        
    }

    if(_wait) return 0;

    //todo deal wityh beginning and end
    uint32_t k=0, forward=0;
    for(int j = 0; j < _kernel_size; j++) {
        for(int i = 0; i < _kernel_size; i++) {

            uint32_t idx = _compute_row_index_counter + i - (_kernel_size>>1);
            uint32_t idy = _compute_col_index_counter + j - (_kernel_size>>1);

            //modulo operation
            if(idy<0){
                idy+=_kernel_size;
            }
            //modulo operation
            if(idy>=_kernel_size){
                idy-=_kernel_size;
            }

            uint64_t sVal = 0;
            if(idx > 0 && idx < _row_length && _col_index_counter-j >0 && _col_index_counter+j <_col_length){
                _memIf->read(ID(idx, idy), sVal);
            }

            forward = _cores[i+j*_kernel_size]->compute_result((uint8_t)(sVal&0xff), forward);
        }
    }

    _compute_row_index_counter += 1;
    if(_compute_row_index_counter >= _row_length*_kernel_size) {
        _compute_row_index_counter = 0;

        _compute_col_index_counter += 1;
        if(_compute_col_index_counter >= _kernel_size) {
            _compute_col_index_counter = 0;
        }

        _col_index_counter += 1;
        if(_col_index_counter >= _col_length) {
            _col_index_counter = 0;
        }
    }

    return forward;
}

void mmu::protected_reset() {

    for (int i = 0; i < _n_cores; ++i) {
        _cores[i]->reset();
    }

    _store_counter=0;
    _compute_row_index_counter=0;
    _compute_col_index_counter=0;
    _col_index_counter=0;
    _wait = 1; 

}

