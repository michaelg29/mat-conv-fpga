
#include "cluster.h"
#include "system.h"
#include "systemc.h"
#include "mat_mult_if.h"
#include "core.h"

#include <iostream>

cluster_if::cluster_if(uint32_t start_group, uint32_t n_groups, uint32_t n_cores)
    : _start_group(start_group), _n_groups(n_groups), _n_cores(n_cores)
{

}


/**
  * @brief  Cluster constructor function.
  * @note   None.
  *
  * @param  name        Give a name to the cluster
  * @param  start_group Offset to the first group to process in the input data
  * @param  n_groups    Number of groups of input data to process
  * @param  n_cores     Number of computation cores in the cluster.
  * @param  kernel_dim  Size of the current kerel
  *
  * @retval None
  */
cluster::cluster(sc_module_name name, uint32_t start_group, uint32_t n_groups, uint32_t n_cores, uint8_t kernel_dim)
    : sc_module(name), cluster_if(start_group, n_groups, n_cores), _kern_dim(kernel_dim)
{

}

void cluster::activate(uint32_t command_type, uint32_t r, uint32_t c) {
    std::cout << "Configured " << command_type << " " << r << " " << c << std::endl;
    // allow cluster to tap the bus data
    _enabled = true;

    // latch configuration
    _command_type = command_type;
    _max_r = r;
    _max_c = c;

    // initialize FSM
    _counter = 0;

    _col_i = 0;
    _kern_val_counter = 0;
}


/**
  * @brief  Cluster reception of data and processing.
  * @note   Receives the kernel values and the input pixels. Will only respond to address TODO.
  *         The cluster must be enabled before this function can be used.
  *
  * @param  addr        Address of the command received
  * @param  data        Pointer to the received data
  * @param  size        Number of bytes received (including the (kernel_dim - 1) pixels buffered pixels from previous payload)
  * @param  out_ptr     Address to store the output pixels.
  *
  * @retval None
  */
void cluster::receiveData(uint64_t addr, uint8_t* data, uint32_t size,  uint8_t *out_ptr){

    // ensure enabled
    if (!_enabled) return;

    // activate for address
    if ((addr & ADDR_MASK) < OFFSET_PAYLOAD) return;

    if (_command_type == MM_CMD_KERN) {
        // store kernel data
        *(uint64_t*)(_kernel_mem + _kern_val_counter) = *(uint64_t*)(data + (_kern_dim - 1)); //Payload stored after the buffered bits
        _kern_val_counter += sizeof(uint64_t);
    }
    else if (_command_type == MM_CMD_SUBJ) {

        cout << "CLUSTER DATA" << endl;

        //Get data for cluster
        memcpy(_input_data, data + _start_group, size); 

        // iterate through data groups
        for(int group_i = 0; group_i < _n_groups; group_i++){ //For each group

            // iterate through kernel rows
            //(start with last to not overwrite subresults)
            int core_i = 0;
            for(int row_i = _kern_dim; row_i >= 0; --row_i){
                
                uint32_t subres = 0;
                if(row_i != 0){ //If first row, no previous subres (is 0)
                    // get previous subresult
                    uint32_t raddr = ((row_i-1) * MAT_COLS) + _col_i; // read address
                    subres = _subres_mem[raddr];
                }                

                // send current kernel row and data group to core to calculate
                subres = core_ifs[core_i]->calculate_row_result(subres, _kernel_mem + (row_i * _kern_dim), _kern_dim, _input_data + group_i);

                if (row_i == (_kern_dim - 1)) { //If last row
                    // output result
                    out_ptr[group_i] = (uint8_t)subres;
                }
                else {
                    // write subresult to internal memory
                    uint32_t waddr = (row_i * MAT_COLS) +  _col_i; // write address
                    _subres_mem[waddr] = subres;
                }

                // move to next core
                core_i = (core_i + 1) % _n_cores;

                // update current column id
                _col_i++;
            }
        }

        // update state
        _counter += _packet_size;

        // update column id if end of row reached
        if((_counter % MAT_COLS) == 0){ //TODO this assumes that the number of columns is a multiple of packet size. Need extra logic if it's not a multiple.
            _col_i = 0;
        }
    }

}



/**
  * @brief  Cluster FSM reset.
  * @note   The cluster is disabled.
  * 
  * @retval None
  */
void cluster::reset() {
    _enabled = false;
}
