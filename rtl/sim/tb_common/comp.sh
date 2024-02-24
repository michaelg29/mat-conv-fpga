#!/bin/bash

# path variables
MODELSIM_HOME=${MODELSIM_HOME:="/home/`whoami`/intelFPGA/20.1/modelsim_ase"}
UVM_HOME=${UVM_HOME:="/home/`whoami`/intelFPGA/20.1/modelsim_ase/verilog_src/uvm-1.2"}
LIB_UVM="libs/uvm-1.2"
export LIB_UVM=${LIB_UVM}

libs=

# parse arguments
while :; do
    case $1 in
        --lib=?*)
            lib="${1#*=}" # delete "--lib="
            libs="${libs} ${lib}"
            ;;
        -?*)
            printf "WARN: Unknown option (ignored): %s\n" "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

# clean libraries
[ -z "${libs}" ] && ./clean.sh
mkdir -p libs

# construct modelsim.ini
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

# compile UVM
if [ ! -d ${LIB_UVM} ]; then
    echo -e "\n\n=====\nCOMPILING UVM\n=====\n\n"
    eval `dirname "$0"`/comp_uvm.sh
    if [ "$?" -ne 0 ]; then
        echo "UVM compile errors"
        exit 1
    fi
fi

# function to compile library at path
function do_compile {
    path=$1
    ([ -z "$path" ] || [ -z "${path%%#*}" ]) && return
    echo -e "\n\n=====\nCOMPILING ${path##*/}\n=====\n\n"
    
    name="${path##*/}_library"
    echo "Compiling ${name} located at ${path}"

    if [ -f ${path}/filelist.txt ]; then
        rm -rf libs/${name}
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

            echo -e "\n"
        done
        if [ "$?" -ne 0 ]; then
            echo "Compile errors in ${path}"
            exit 1
        fi
    else
        echo "Could not find ${path}/filelist.txt, exiting."
        exit 1
    fi
}

# compile all libraries
if [ -z "${libs}" ]; then
    echo "Compiling libs in dependencies.txt"
    cat dependencies.txt |
    while read path; do
        do_compile $path
    done
else
    echo "Compiling libs: $libs"
    for path in "${libs[@]}"; do
        do_compile $path
    done
fi
