#!/bin/bash

MODELSIM_HOME=${MODELSIM_HOME:="/home/`whoami`/intelFPGA/20.1/modelsim_ase"}
UVM_HOME=${UVM_HOME:="/home/`whoami`/intelFPGA/20.1/modelsim_ase/verilog_src/uvm-1.2"}
LIB_UVM="libs/uvm-1.2"
export LIB_UVM=${LIB_UVM}

./clean.sh
mkdir -p libs

echo "" > modelsim.ini
cat ${MODELSIM_HOME}/modelsim.ini |
while read line; do
    echo $line >> modelsim.ini
    if [ "$line" = "[Library]" ]; then
        cat dependencies.txt |
        while read path; do
            name="${path##*/}_library"
            echo "${name} = libs/${name}" >> modelsim.ini
        done
        echo "" >> modelsim.ini
    fi
done

if [ ! -d ${LIB_UVM} ]; then
    echo "Compiling UVM"
    eval `dirname "$0"`/comp_uvm.sh
    if [ "$?" -ne 0 ]; then
        echo "UVM compile errors"
        exit 1
    fi
fi

cat dependencies.txt |
while read path; do
    ([ -z "$path" ] || [ -z "${path%%#*}" ]) && continue
    name="${path##*/}_library"
    echo "Compiling ${name} located at ${path}"
    if [ -f ${path}/filelist.txt ]; then
        vlib libs/${name}
        cat ${path}/filelist.txt |
        while read file; do
            ([ -z "$file" ] || [ -z "${file%%#*}" ]) && continue
            echo "${path}/${file}"
            ext=${file##*.}
            if [[ $ext = "vhd" ]]; then
                echo "Compiling ${file} as VHDL"
                vcom -work libs/${name} ${path}/${file}
            elif [[ $ext = "sv" ]]; then
                echo "Compiling ${file} as SV"
                vlog -work libs/${name} -L ${LIB_UVM} ${path}/${file} +incdir+$UVM_HOME/src
            else
                echo "Unrecognized extension ${ext} in file ${path}/${file}"
            fi
            if [ "$?" -ne 0 ]; then
                echo "Compile errors in ${file}"
                exit 1 # break out of loop with error
            fi
        done
        if [ "$?" -ne 0 ]; then
            echo "Compile errors in ${path}"
            exit 1
        fi
    else
        echo "Could not find ${path}/filelist.txt, exiting."
        exit 1
    fi
done
