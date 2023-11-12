#!/bin/bash

TB_TOP=${TB_TOP:="tb_top"}
UVM_HOME=${UVM_HOME:="/home/`whoami`/intelFPGA/20.1/modelsim_ase/verilog_src/uvm-1.2"}
echo "UVM_HOME: ${UVM_HOME}"

# clean library list
parent_pid=$$
echo -n "" > /tmp/lib_list$$

# loop through all libraries
export parent_pid
cat dependencies.txt |
while read path; do
    name="${path##*/}_library"
    echo "Loading ${name} located at ${path}"
    if [ -d "libs/${name}" ]; then
        echo -n " -L libs/${name}" >> /tmp/lib_list${parent_pid}
    else
        echo "Could not find libs/${name} library, exiting."
        exit 1
    fi
done

lib_list="-sv_lib ${UVM_HOME}/lib/uvm_dpi -L libs/uvm-1.2 "`cat /tmp/lib_list$$ `
last_lib=${lib_list##*-L}

vsim -c ${last_lib}.${TB_TOP} -do run.do ${lib_list} -voptargs=+acc -work ${last_lib}
