
# Scripts

This directory contains general purpose scripts for the project.

## `cron.sh`

This script is used to run specific testbenches on a specific branch of the repository.

### Environment setup

To make this script runnable, the user's `.profile` file must have the environment variables to indicate to the script of where to compile and run simulations. Additionally, look to the [hdl README](./../rtl/README.md) for more environment variables, which the list below also includes.

* `MAT_CONV_BRANCH_NAME`: Name of a branch on the repository.
  * e.g. `export MAT_CONV_BRANCH_NAME="RTL/InputFSM"`
* `MAT_CONV_TBS`: List of testbenches to compile.
  * e.g. `export MAT_CONV_TBS=("tb_mac" "tb_core")
* `PATH="${PATH}:~/intelFPGA_pro/20.1/modelsim_ae/bin"`
* `MODELSIM_HOME="~/intelFPGA_pro/20.1/modelsim_ae"`
* `UVM_HOME="~/intelFPGA_pro/20.1/modelsim_ae/verilog_src/uvm-1.2"`
  
First, clone the repository to a specific path. The example below cloned the repository to `/home/<USERNAME>/src/mat_mult_fpga`. Ensure the system has automatic pull access to the repository. This can be achieved with [SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=webui&platform=linux). The commands below show how to get the key to put in GitHub. Ensure there is no password needed to use the key, otherwise the automatic cronjob will not be able to access the repository without user intervention (which kind of defeats the purpose of the automatic job).

```
ssh-keygen -t rsa -b 4096
cat ~/.ssh/id_rsa.pub # copy this value to the clipboard to paste on GitHub
```

To test the SSH key, clone the repository using the command below. It should not prompt for a username or password at any point.

```
mkdir -p ~/src
cd ~/src
git clone ssh://git@github.com:/michaelg29/mat_mult_fpga.git ./mat_mult_fpga
cd ./mat_mult_fpga
git pull
```

### Cronjob creation

To have the script execute on a schedule, run the command `crontab -e`. This will open up a text editor. Add the following line:

```
30 14 * * 1-5 /home/<USERNAME>/src/mat_mult_fpga/scripts/cron.sh
```

This specific example schedules the script for execution at 14:30 every weekday. Update the script path above to point to the location of the script.

### Script output

This script will pull from the repository, checkout the branch specified in `MAT_CONV_BRANCH_NAME`. Then, it will compile each testbench listed in `MAT_CONV_TBS`, and write the output of the compilation to a new file in the `reports` directory.
