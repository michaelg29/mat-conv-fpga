
# Modeling

The folders contain code to simulate the matrix multiplier across different abstraction levels.

## Folders

### include - Common header files

### src - Common source files defining common functions

### `0-appl`: The golden model

This model is considered the "Golden Model" as it is implemented completely through software instructions. There are no simulated delays, and is used as a reference for the rest of the models. This model processes the data by loading in the entire matrix via the command payload then convolving it with the loaded kernel.

### `0-1-golden-alg`: The golden model for the algorithm

This golden model is a proof for the algorithm to be implemented in the module. The main module (`mat_mult_ga`) in this folder extends from the main module in `0-appl` (`mat_mult`), so the command decoding is maintained. However, the main receive method in `mat_mult_ga` will intercept the payload data as it is received. Instead of being routed to the internal memory in the superclass, it will go to be processed by the `cluster` class.

### `0-2-golden-wait`: The golden model for the wait method

This golden model implements the method of waiting for all the data to compute a single kernel result.

### `1-task`: The task-level model

This model builds on the previous by dividing the processing into multiple tasks. This models how each core behaves autonomously and with feedback and commands from the state machines.

Each module instance has its own `SC_THREAD`, implemented through the class' defined `main` function. The general structure is as follows:
```cpp
void module::enable() {
    _enabled = true;
}

int module::get_result() {
    return _result;
}

void module::main() {
    // local copies of interface variables
    bool enabled;
    
    // local variables
    int i;
    
    while (true) {
        // capture values on posedge
        enabled = _enabled;
        YIELD();
        
        // compute and update
        if (enabled) {
            _result = i;
            ext_if->call_if(); // external interface call
            i++;
        }
        
        // next posedge
        POS_CORE();
    }
}
```

The module has defined interface functions, `enable` and `get_result`, modeling the signals that other classes can toggle. At the beginning of each rising edge of the simulated clock, the module captures the external interface signals locally. Through the call to `YIELD`, the module calls a `wait(0)` statement to ensure that all threads have caught up to the current cycle and captured their external interface signals. Then, the module can update its result value depending on the local copies. Following the per-cycle computation, the module will wait for the next cycle through the call to `POS_CORE()`.

The goal is to synchronize all threads while ensuring that calls to interface functions do not overwrite external interface values. The call to `YIELD` forces all running threads at the current clock cycle to allow other threads to capture their values. Hence, even if a thread calls another thread's external interface function in that cycle, the receiver thread maintains the local value at the beginning of the clock cycle.

### `2-tlm`: The transaction-level model

### `3-bfm`: The bus functional model

### `4-casim`: The cycle-accurate simulator

## Running instructions

`make run [MEM_FILE=<MEM_FILE>] [KERNEL_SIZE=<KERNEL_SIZE>] [DO_RANDOM=<0|1>]`

The program loads in a matrix of size 1920x1080, starting at `0`, and a kernel of size `KERNEL_SIZE`x`KERNEL_SIZE`, starting at `1920x1080`, both from `MEMORY_FILE`. It then convolves the two, and writes the output to `MEMORY_FILE`. To randomize the memory file (needed on the initial run), specify `DO_RANDOM=1`.

### Validation

To validate the outputs in the mem_init file, execute the Python script as follows:

`python3 ./../cmp.py <mem_file> <kern_size> [step_size]`

The script reads memory from `mem_file`. It performs the matrix convolution using a kernel of size `kern_size`, just as the golden model does. To make the validation faster, set `step_size` to specify how many elements to skip in between checks.
