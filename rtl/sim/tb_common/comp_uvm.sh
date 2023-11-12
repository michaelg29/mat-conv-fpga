#!/bin/bash

#########################
### Required packages ###
#########################
# sudo apt-get install gcc g++ gcc-multilib g++-multilib

MODELSIM_HOME=${MODELSIM_HOME:="/home/`whoami`/intelFPGA/20.1/modelsim_ase"}
UVM_HOME=${UVM_HOME:="/home/`whoami`/intelFPGA/20.1/modelsim_ase/verilog_src/uvm-1.2"}
echo "UVM_HOME: ${UVM_HOME}"
LIB_UVM="libs/uvm-1.2"

mkdir -p ${LIB_UVM}
vlog -64 -lint -quiet -sv17compat -suppress vlog-2186 -work ${LIB_UVM} ${UVM_HOME}/src/uvm_pkg.sv +incdir+$UVM_HOME/src
vlog -64 -lint -quiet -sv17compat -suppress vlog-2186 -work ${LIB_UVM} ${UVM_HOME}/src/uvm.sv +incdir+$UVM_HOME/src

mkdir -p $UVM_HOME/lib
g++ -m32 -fPIC -DQUESTA -g -W -shared -I${MODELSIM_HOME}/include ${UVM_HOME}/src/dpi/uvm_dpi.cc -o ${UVM_HOME}/lib/uvm_dpi.so
#g++ -m64 -fPIC -DQUESTA -g -W -shared -I${MODELSIM_HOME}/include ${UVM_HOME}/src/dpi/uvm_dpi.cc -o ${UVM_HOME}/lib/uvm_dpi64.so
