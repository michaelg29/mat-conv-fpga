
#include <map>
#include <sstream>

#include "systemc.h"

#ifndef SC_TRACE_HPP
#define SC_TRACE_HPP

/** SystemC signal and variable tracer wrapper. */
class sc_tracer; // forward declaration for global singleton
class sc_tracer {

    public:

        /** Global singleton instance */
        static sc_tracer tracer;

        /** Initializer specifying output file. */
        static void init(const char *out_file, sc_time_unit time_unit) {
            if (tracer._enabled) {
                std::cout << "Opening trace file " << out_file << std::endl;
                tracer._tf = sc_create_vcd_trace_file(out_file);
                tracer._tf->set_time_unit(1, time_unit);
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

        /** Trace a signal. */
        template <class T>
        static void trace(T& value, std::string module_name, const char *signal_name) {
            trace(value, sc_module_name(module_name.c_str()), signal_name);
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

// trackable class types
enum trackable_class_e {
    REDUNDANT_COMMAND,
    REDUNDANT_RESPONSE,
    TRACKABLE_CLASS_NONE
};
#define NUM_TRACKABLE_CLASSES TRACKABLE_CLASS_NONE

// information about tracked data
struct trackable_data_t {
    trackable_class_e data_class;
    uint32_t publish_time;
};

/** Class to track latency of data across the NoC. */
class latency_tracker; // forward declaration for global singleton
class latency_tracker {

    public:

        /** Global singleton instance */
        static latency_tracker tracker;

        /** Publish a tracker. */
        template <class T, class U = uint32_t>
        static void publish(trackable_class_e data_class, T* data, U* data2 = nullptr) {
            // calculate checksum for key
            uint32_t chksum = 0;
            uint32_t *ptr = (uint32_t*)data;
            for (int i = 0; ptr && i < sizeof(T); i += sizeof(uint32_t), ptr++) {
                chksum ^= *ptr;
            }
            ptr = (uint32_t*)data2;
            for (int i = 0; ptr && i < sizeof(U); i += sizeof(uint32_t), ptr++) {
                chksum ^= *ptr;
            }

            // insert into map
            trackable_data_t data_struct;
            data_struct.data_class = data_class;
            data_struct.publish_time = (uint32_t)sc_time_stamp().to_double();
            tracker._tracked_data[chksum] = data_struct;
        }

        /** Capture a tracker. */
        template <class T, class U = uint32_t>
        static void capture(T* data, U* data2 = nullptr) {
            // calculate checksum for key
            uint32_t chksum = 0;
            uint32_t *ptr = (uint32_t*)data;
            for (int i = 0; ptr && i < sizeof(T); i += sizeof(uint32_t), ptr++) {
                chksum ^= *ptr;
            }
            ptr = (uint32_t*)data2;
            for (int i = 0; ptr && i < sizeof(U); i += sizeof(uint32_t), ptr++) {
                chksum ^= *ptr;
            }

            // fetch from dictionary
            std::map<uint32_t, trackable_data_t>::const_iterator it = tracker._tracked_data.find(chksum);
            if (it != tracker._tracked_data.end()) {
                // found in map
                trackable_data_t entry = it->second;
                tracker._durations[entry.data_class] += (uint32_t)sc_time_stamp().to_double() - entry.publish_time;
                tracker._counts[entry.data_class]++;

                // remove from map
                tracker._tracked_data.erase(it);
            }
        }

        /** Print the report. */
        static void print_report(std::ostream& out = std::cout) {
            for (uint32_t c = (uint32_t)REDUNDANT_COMMAND; c < (uint32_t)TRACKABLE_CLASS_NONE; c++) {
                out << "Class " << c << ": total duration " << tracker._durations[c] << " over " << tracker._counts[c] << " packets, average of " << ((double)tracker._durations[c] / (double)tracker._counts[c]) << " ticks per packet." << std::endl;
            }
            out << tracker._tracked_data.size() << " outstanding packets." << std::endl;
        }

    private:

        // list of tracked values
        std::map<uint32_t, trackable_data_t> _tracked_data;

        // total durations
        uint32_t _durations[NUM_TRACKABLE_CLASSES];
        uint32_t _counts[NUM_TRACKABLE_CLASSES];

};

#endif // SC_TRACE_HPP
