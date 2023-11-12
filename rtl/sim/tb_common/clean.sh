#!/bin/bash

LIB_UVM=${LIB_UVM:=""}

echo "Cleaning libraries directory"
ls -1 --group-directories-first libs |
while read dir; do
    if [ ! -d "libs/${dir}" ]; then
        break;
    fi
    
    if [ "libs/$dir" != "$LIB_UVM" ]; then
        rm -r libs/${dir}
    fi
done
