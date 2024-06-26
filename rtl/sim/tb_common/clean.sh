#!/bin/bash

LIB_UVM=${LIB_UVM:=""}

! [ -d ./libs ] && echo "No libraries to clean" && exit 0

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

rm -rf ./logs
rm -f *.vstf
rm -f *.wlf
