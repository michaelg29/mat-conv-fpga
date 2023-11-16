
#include "systemc.h"

#include <math.h>

#ifndef MEM_IF_HPP
#define MEM_IF_HPP

/**
 * Interface with memory to be overridden for different abstraction levels.
 *
 * @tparam data_t The type of data stored in the memory.
 * @tparam addr_t The type of address. Defaults to uint64_t.
 */
template <typename data_t, typename addr_t = uint64_t>
class memory_if : virtual public sc_interface {

    public:

        memory_if(sc_module_name name, uint32_t mem_size) : _name(name), _mem_size(mem_size)
        {
            std::cout << "Memory with name " << _name << std::endl;
            _reads = (uint32_t*)malloc(mem_size * sizeof(uint32_t));
            _writes = (uint32_t*)malloc(mem_size * sizeof(uint32_t));
        }

        /**
         * Read data from the memory.
         *
         * @param addr The address to read from.
         * @param data Variable holding the output.
         * @retval     Whether the read was successful.
         */
        bool read(addr_t addr, data_t& data) {
            bool success = do_read(addr, data);
            if (success) _reads[addr] += 1;
            return success;
        }

        /**
         * Write data to the memory.
         *
         * @param addr The address to write to.
         * @param data The data to write.
         * @retval     Whether the write was successful.
         */
        bool write(addr_t addr, data_t data){
            bool success = do_write(addr, data);
            if (success) _writes[addr] += 1;
            return success;
        }

        void print_report() {
            std::cout << "Memory " << _name << std::endl;
            analyze_array("Reads", _reads, _mem_size);
            analyze_array("Writes", _writes, _mem_size);
        }
        sc_module_name _name;

    protected:

        /** Statistics. */
        uint32_t _mem_size;
        uint32_t *_reads;
        uint32_t *_writes;

        /** Subclass methods specify internal functionality of the memory. */
        virtual bool do_write(addr_t addr, data_t data) = 0;
        virtual bool do_read(addr_t addr, data_t& data) = 0;

    private:

        void analyze_array(const char *arr_name, uint32_t *arr, uint32_t n) {
            double mean = 0.0;
            double max = 0.0;
            double stddev = 0.0;

            // calculate mean
            for (uint32_t i = 0; i < n; ++i) {
                mean += (double)arr[i];
                if (arr[i] > max) {
                    max = (double)arr[i];
                }
            }
            mean /= (double)n;

            // calculate standard deviation
            for (uint32_t i = 0; i < n; ++i) {
                double var = arr[i] - mean;
                stddev += var * var;
            }
            stddev = sqrt(stddev / (double)(n - 1));

            std::cout << arr_name << " per address: Mean " << mean << ", maximum " << max << ", stddev " << stddev << std::endl;
        }

};

/**
 * Interface with memory to be overridden for different abstraction levels.
 *
 * @tparam data_t The type of data stored in the memory.
 * @tparam addr_t The type of address. Defaults to uint64_t.
 */
template <typename data_t, typename addr_t = uint64_t>
class simple_memory_mod : public sc_module, public memory_if<data_t, addr_t> {

    public:

        simple_memory_mod(sc_module_name name, uint8_t *memory, uint64_t mem_size)
            : sc_module(name), memory_if<data_t, addr_t>(name, mem_size), memory(memory), mem_size(mem_size) {}

    private:

        bool do_read(addr_t addr, data_t& data) {
            if (!check_addr(addr)) return false;
            data = *(addr_t*)(memory + addr);
            return true;
        }

        bool do_write(addr_t addr, data_t data) {
            if (!check_addr(addr)) return false;
            *((data_t*)(memory + addr)) = data;
            return true;
        }

        uint8_t *memory;
        uint64_t mem_size;

        bool check_addr(uint64_t addr) {
            return addr < mem_size;
        }

};

#endif // MEM_IF_HPP
