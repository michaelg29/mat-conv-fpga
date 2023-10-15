cmake_minimum_required(VERSION 3.1)
project(simple_perf CXX)

set (CMAKE_PREFIX_PATH "C:/Program Files/SystemC")
find_package(SystemCLanguage CONFIG REQUIRED)

set (CMAKE_CXX_STANDARD ${SystemC_CXX_STANDARD} CACHE STRING
     "C++ standard to build all targets. Supported values are 98, 11, 14, and 17.")
set (CMAKE_CXX_STANDARD_REQUIRED ${SystemC_CXX_STANDARD_REQUIRED} CACHE BOOL
     "The with CMAKE_CXX_STANDARD selected C++ standard is a requirement.")



add_executable(${PROJECT_NAME} main.cpp ../m_fifo.cpp ../mat_mult_if.cpp ../system.cpp)

target_include_directories(${PROJECT_NAME} ../include PUBLIC)

target_link_libraries(${PROJECT_NAME} SystemC::systemc)