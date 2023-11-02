
#include "mmu.h"
#include "systemc.h"
#include "system.h"


mmu::mmu(sc_module_name name, uint32_t n_cores, uint32_t row_length, uint32_t kernel_size) 
        : sc_module(name), _n_cores(n_cores), _row_length(row_length), _kernel_size(kernel_size)
{
    _lsram = new lsram("LSRAM");

    _cur_state = LOAD_KERN;

    for (int i = 0; i < _n_cores; ++i) {
        // initialize each core
        _cores[i] = new core(("core" + std::to_string(i)).c_str());
    }

    for (int i = 0; i < _n_cores-1; ++i) {
        // connect each core
        _cores[i]->forward = &(_cores[i+1]->addInput);
    }

    //TODO connect output FSM
    //_cores[_n_cores-1]->addInput = *(OUTFSM->in);
}


void mmu::store(uint8_t nextVal) {

    switch (_cur_state)
    {
    case LOAD_KERN:
        if(_core_load_counter < _n_cores)
            _cores[_core_load_counter]->setKernelValue(nextVal);
        _core_load_counter+=1;
        break;

    case SUBJ_PROCESSING:
        _lsram->store(_store_counter, nextVal);

        _store_counter += 1;
        if(_store_counter >= _row_length*_kernel_size) {
            _store_counter = 0;
        }
        break;
    }

    
}

void mmu::compute_output() {
    if(_store_counter >= (_kernel_size*(1+_row_length>>1)-1)) {
        _wait = 0;        
    }

    if(_wait) return;

    //todo deal wityh beginning and end
    uint32_t k=0;
    for(int j = 0; j < _kernel_size; j++) {
        for(int i = 0; i < _kernel_size; i++) {

            int32_t idx = _compute_row_index_counter + i - (_kernel_size>>1);
            int32_t idy = _compute_col_index_counter + j - (_kernel_size>>1);

            //modulo operation
            if(idy<0){
                idy+=_kernel_size;
            }
            //modulo operation
            if(idy>=_kernel_size){
                idy-=_kernel_size;
            }

            uint8_t sVal = 0;
            if(idx >= 0 && idx < _row_length && (_col_index_counter-j >= 0) && (_col_index_counter+j <_col_length)){
                sVal = _lsram->load(ID(idx, idy));
            }

            _cores[i+j*_kernel_size]->compute_result(sVal);
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

}

void mmu::protected_reset() {

    for (int i = 0; i < _n_cores; ++i) {
        _cores[i]->reset();
    }

    _core_load_counter=0;
    _store_counter=0;
    _compute_row_index_counter=0;
    _compute_col_index_counter=0;
    _col_index_counter=0;
    _wait = 1; 

    _cur_state = LOAD_KERN;

    _lsram->reset();
    
}


void mmu::setProcessingState() {
    _cur_state = SUBJ_PROCESSING;
}