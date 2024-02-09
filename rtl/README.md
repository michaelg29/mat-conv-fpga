# ModelSim installation

## Linux
### Ubuntu 22.04 LTS
As found here: https://stackoverflow.com/questions/76335589/modelsim-install-in-ubuntu-22-04

Run the following commands to install the dependencies for ModelSim:
* sudo dpkg --add-architecture i386
* sudo apt-get update
* sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 lib32ncurses6 libxft2 libxft2:i386 libxext6 libxext6:i386


Download the ModelSim Linux installer from: https://www.intel.com/content/www/us/en/software-kit/750666/modelsim-intel-fpgas-standard-edition-software-version-20-1-1.html

Make the installer an executable with the following command:
* chmod +x ModelSimSetup-20.1.1.720-linux.run

Run the installer:
* ./ModelSimSetup-20.1.1.720-linux.run


You can then add the path to the binaries in the ~/.profile file.
By default, the path is ~/intelFPGA/20.1/modelsim_ase/bin


You also need to install the following dependencies for UVM (otherwise errors will ensue):
* sudo apt-get install gcc g++ gcc-multilib g++-multilib



# RTL Coding

## Directory Structure

The folder `hdl` contains all the VHDL and SV design files. Each subfolder represents a module (top-level, submodule, testbench, ...), and has one or more .vhdl or .sv files. With it, there must be a file named `filelist.txt`. That file must list each design file on a new line, and must end with a new line. Order of specification matters.

The folder `sim` contains the scripts needed to compile and simulate the testbenches and their DUT modules. To create a new testbench to be able to compile designs, copy the `tb_template` directory and rename it to the new testbench (i.e. `cp tb_template tb_<MY_TESTBENCH>`). Before running, update the file `dependencies.txt`, which provides paths to the directories containing the relevant design files. These paths must be relative to the directory in `sim`. The order matters, much like with `filelist.txt`. The files `run.do` and `wave.do` are modifiable, and can be customized to suit the specific simulation and waveform needs.

## Coding style

### UVM reporting

The testbench modules use UVM reporting for errors and information. This is through the macros below. Here, `tb_top` is the name of the module attached to the log, `sformatf` allows a printf-style output, and `UVM_NONE` is the severity level. The script `sim.sh` will detect instances of `uvm_error`, and will exit the script with an error code when it finds those messages. This is useful for final reporting.

```
`uvm_info("tb_top", $sformatf("oreg[20:3]: %d ; oreg: %d ; o_res: %d",oreg[20:3], oreg, o_res), UVM_NONE);
`uvm_error("tb_top", $sformatf("Test failed for i: %d; j: %d; k: %d", i, j, k));
```

## Required environment

To run the scripts, the following environment variables must be present. It is easiest to set this in the `.bashrc` file.

```
PATH="${PATH}:~/intelFPGA_pro/20.1/modelsim_ae/bin"
MODELSIM_HOME="~/intelFPGA_pro/20.1/modelsim_ae"
UVM_HOME="~/intelFPGA_pro/20.1/modelsim_ae/verilog_src/uvm-1.2"
```

This assumes that the intelFPGA installation is present in the home directory.

## Running instructions

Each directory within `sim` contains Linux bash scripts for compilation and simulation.

To clean up the directory, execute `./clean.sh`.

To compile the design files pointed to in `dependencies.txt`, execute `./comp.sh`.

To run a simulation of the single top-level module, execute `./sim.sh`. To customize the run sequence, update `run.do`.

Running the simulation generates a waveform in `vsim.wlf`. To view that waveform, run `./view.sh`. To customize the pre-set view, update `wave.do`. You can also save the current waveform you are viewing in Modelsim by selecting `File > Save Format` or (`ctrl+S`).

### CMC licenses

Before running vsim, make sure that the proper licenses for Questa Standard Edition are installed. Follow instructions to install [CADPass](https://account.cmc.ca/WhatWeOffer/Products/CMC-00200-07055.aspx), then login and verify the licenses. Ensure the environment variable `LM_LICENSE_FILE` is set for the current user, it should look something like `XXXX@a2.cmc.ca`.

If not, open up the CADPass client, select `My Info` on the left hand side, press `Show License details` to open up a new window. Then, navigate to `Intel FPGA Development Tools` > `LM_LICENSE_FILE` to get the value that it should be. Then set that as the computer's environment variable `LM_LICENSE_FILE`.

To be able to run vsim, ensure the appgate SDP application running. It must have an internet connection to be able to connect to the license server.

### Known issues

If there are compilation errors, please triple check the environment variables first.

#### UVM Errors with GCC

This happens when trying to compile or run UVM. This may be from the compiler looking to an old version of GCC. To resolve this, ensure first that gcc is installed on the machine and is present in the `PATH` variable. Then, go to the `MODELSIM_HOME` directory and rename the GCC directories:

```
pushd ${MODELSIM_HOME}
mv gcc-4.7.4-linux/ _gcc-4.7.4-linux
mv gcc-4.5.0-linux/ _gcc-4.5.0-linux
mv gcc-4.3.3-linux/ _gcc-4.3.3-linux
```

This forces Modelsim to look at the GCC version installed on your machine as opposed to the one that comes with Modelsim.

#### Other missing packages

The following packages on Linux may help resolve errors:

```
sudo apt-get install gcc g++\
    gcc-multilib g++-multilib \
    libext-dev
```

There may also be architecture discrepancies. Try the following:

```
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get --fix-broken install
sudo apt-get install libxext-dev:i386 libxft2:i386
```
