
#include <sstream>

#include "systemc.h"

#ifndef SC_TRACE_HPP
#define SC_TRACE_HPP

class sc_tracer;

class sc_tracer {

    public:

        /** Global instance */
        static sc_tracer tracer;

        /** Constructor specifying output file. */
        static void init(const char *out_file) {
            if (tracer._enabled) {
                std::cout << "Opening trace file " << out_file << std::endl;
                tracer._tf = sc_create_vcd_trace_file(out_file);
                tracer._tf->set_time_unit(1, SC_NS);
            }
        }

        /** Trace a signal. */
        template <class T>
        static void trace(T& value, sc_module_name module_name, const char *signal_name) {
            if (tracer._enabled) {
                std::ostringstream ss;
                ss << module_name << "." << signal_name;
                sc_trace(tracer._tf, value, ss.str().c_str());
            }
        }
        
        /** Trace a signal. */
        template <class T>
        static void trace(T& value, const char *module_name, const char *signal_name) {
            trace(value, sc_module_name(module_name), signal_name);
        }

        /** Comment. */
        static void comment(std::string comment) {
            sc_write_comment(tracer._tf, comment);
        }

        /** Write the file. */
        static void close() {
            if (tracer._tf) {
                std::cout << "Writing trace file" << std::endl;
                sc_close_vcd_trace_file(tracer._tf);
                tracer._tf = nullptr;
            }
        }

        /** Disable tracing. */
        static void disable() {
            tracer._enabled = false;
        }

        /** Enable tracing. */
        static void enable() {
            tracer._enabled = true;
        }

    private:

        // enable signal
        bool _enabled = true;

        // local file handle
        sc_trace_file *_tf = nullptr;

};

#endif // SC_TRACE_HPP
