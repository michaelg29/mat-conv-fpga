#!/bin/bash

sudo apt-get install gcc g++ \
  gcc-multilib g++-multilib \
  libxext-dev

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get --fix-broken install
sudo apt-get install libxext-dev:i386 libxft2:i386

# e.g. MODELSIM_HOME=~/intelFPGA_pro/20.1/modelsim_ae
pushd ${MODELSIM_HOME}
#mv gcc-4.7.4-linux/ _gcc-4.7.4-linux
#mv gcc-4.5.0-linux/ _gcc-4.5.0-linux
#mv gcc-4.3.3-linux/ _gcc-4.3.3-linux
