
# Modeling

The folders contain code to simulate the matrix multiplier across different abstraction levels.

## Folders

### include - Common header files

### src - Common source files defining common functions

### `00-appl`: The golden model

This model is considered the "Golden Model" as it is implemented completely through software instructions. There are no simulated delays, and is used as a reference for the rest of the models. This model processes the data by loading in the entire matrix via the command payload then convolving it with the loaded kernel.

### `01-task`: The task-level model

## Running instructions

`./system <MEMORY_FILE> <KERNEL_SIZE>`

The program loads in a matrix of size 1920x1080, starting at `0`, and a kernel of size `KERNEL_SIZE`x`KERNEL_SIZE`, starting at `1920x1080`, both from `MEMORY_FILE`. It then convolves the two, and writes the output to `MEMORY_FILE`.
