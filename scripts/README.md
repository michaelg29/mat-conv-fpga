
# Scripts

This directory contains general purpose scripts for the project.

## `cron.sh`

This script is used to run specific testbenches on a specific branch of the repository.

### Environment setup

To make this script runnable, the user's `.bashrc` file must have the following environment variables:

* `MAT_CONV_BRANCH_NAME`: Name of a branch on the repository.
  * e.g. `export MAT_CONV_BRANCH_NAME="RTL/InputFSM"`
* `MAT_CONV_TBS`: List of testbenches to compile.
  * e.g. `export MAT_CONV_TBS=("tb_mac" "tb_core")

### Cronjob creation

To have the script execute on a schedule, run the command `crontab -e`. This will open up a text editor. Add the following line:

```
30 14 * * 1-5 /home/<USERNAME>/src/mat_mult_fpga/scripts/cron.sh
```

This specific example schedules the script for execution at 14:30 every weekday. Update the script path above to point to the location of the script.

### Script output

This script will pull from the repository, checkout the branch specified in `MAT_CONV_BRANCH_NAME`. Then, it will compile each testbench listed in `MAT_CONV_TBS`, and write the output of the compilation to a new file in the `reports` directory.
