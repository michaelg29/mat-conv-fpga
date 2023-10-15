
# Modeling

The folders contain code to simulate the matrix multiplier across different abstraction levels.

## Folders

### include - Common header files

### src - Common source files defining common functions

### `00-appl`: The Golden Model

This model is considered the "Golden Model" as it is implemented completely through software. There are no simulated delays, and is used as a reference for the rest of the models.

## Running instructions

`./main <INPUT_FILE> <OUTPUT_FILE> <KERNEL_FILE> <KERNEL_SIZE> [<DO_RANDOMIZE>]`

The program loads in a matrix of size 1920x1080 from `INPUT_FILE`, and a kernel of size `KERNEL_SIZE`x`KERNEL_SIZE` from `KERNEL_FILE`. It then convolves the two, and writes the output to `OUTPUT_FILE`.
