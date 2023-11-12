
#include "systemc.h"

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

        /**
         * Write data to the memory.
         *
         * @param addr The address to write to.
         * @param data The data to write.
         * @retval     Whether the write was successful.
         */
        bool write(addr_t addr, data_t data){
            bool success = do_write(addr, data);
            return success;
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
            return success;
        }

    protected:

        virtual bool do_write(addr_t addr, data_t data) = 0;
        virtual bool do_read(addr_t addr, data_t& data) = 0;

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

        simple_memory_mod(sc_module_name name, uint8_t *memory, uint64_t mem_size) : sc_module(name), memory(memory), mem_size(mem_size) {}
    
    private:

        bool do_write(addr_t addr, data_t data) {
            if (!check_addr(addr)) return false;
            *((data_t*)(memory + addr)) = data;
            return true;
        }

        bool do_read(addr_t addr, data_t& data) {
            if (!check_addr(addr)) return false;
            data = *(addr_t*)(memory + addr);
            return true;
        }

        uint8_t *memory;
        uint64_t mem_size;

        bool check_addr(uint64_t addr) {
            return addr < mem_size;
        }

};

#endif // MEM_IF_HPP
