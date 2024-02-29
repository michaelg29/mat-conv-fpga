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

# function to run testbench with arguments
function do_run {
    args=$1
}

# function to run testcase
function do_sim {
    name=$1
    args=$2
    logname="./logs/${name}.log"

    echo "Executing test ${name} with args ${args}"

    echo -n "" > ${logname}

    # run simulation
    command="vsim -c ${last_lib}.${TB_TOP} -do run.do ${lib_list} -voptargs=+acc -work ${last_lib} ${args}"
    eval $command | {
        while read -r line; do
            echo $line
            echo $line >> ${logname}
        done
    }

    # analyze log
    n_uvm_error=`grep -rn "UVM_ERROR" ${logname} | wc -l`
    n_uvm_warning=`grep -rn "UVM_WARNING" ${logname} | wc -l`
    echo -e "\n\n"
    echo "Number of UVM_ERROR messages: $n_uvm_error"
    echo "Number of UVM_WARNING messages: $n_uvm_warning"
    echo -e "\n\n"
}

# run all testcases
mkdir -p ./logs
if [ -f args.ini ]; then
    cat args.ini |
    while read line; do
        name="${line%%:*}"
        args="${line##*:}"
        ! ([ -z "$line" ] || [ -z "${line%%#*}" ]) && do_sim "${name}" "${args}"
    done
else
    do_sim "tc" ""
    [ $? -gt 0 ] && echo "Exiting with error" && exit 1
fi

echo "Exiting" && exit 0
