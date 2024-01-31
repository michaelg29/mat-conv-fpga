
# RTL Coding

## Directory Structure

The folder `hdl` contains all the VHDL and SV design files. Each subfolder represents a module (top-level, submodule, testbench, ...), and has one or more .vhdl or .sv files. With it, there must be a file named `filelist.txt`. That file must list each design file on a new line, and must end with a new line. Order of specification matters.

The folder `sim` contains the scripts needed to compile and simulate the testbenches and their DUT modules. To create a new testbench to be able to compile designs, copy the `tb_template` directory and rename it to the new testbench (i.e. `cp tb_template tb_<MY_TESTBENCH>`). Before running, update the file `dependencies.txt`, which provides paths to the directories containing the relevant design files. These paths must be relative to the directory in `sim`. The order matters, much like with `filelist.txt`. The files `run.do` and `wave.do` are modifiable, and can be customized to suit the specific simulation and waveform needs.

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

### Known issues

If there are compilation errors, please triple check the environment variables first.

#### fatal error: vpi_user.h: No such file or directory

This happens when trying to compile UVM. This may be from the compiler looking to an old version of GCC. To resolve this, ensure first that gcc is installed on the machine and is present in the `PATH` variable. Then, go to the `MODELSIM_HOME` directory and rename the GCC directories:

```
pushd ${MODELSIM_HOME}
mv gcc-4.7.4-linux/ _gcc-4.7.4-linux
mv gcc-4.5.0-linux/ _gcc-4.5.0-linux
mv gcc-4.3.3-linux/ _gcc-4.3.3-linux
```

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
