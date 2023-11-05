
from sys import argv

MAT_ROWS = 1080
MAT_COLS = 1920
MAT_SIZE = MAT_ROWS * MAT_COLS

MAX_KERN_ROWS = 5
MAX_KERN_SIZE = MAX_KERN_ROWS**2
KERN_SIZE_ROUNDED = ((((MAX_KERN_SIZE) >> 3) + 1) << 3)

MEM_SIZE = MAT_SIZE + KERN_SIZE_ROUNDED + MAT_SIZE

MAT_ADDR = 0
KERN_ADDR = MAT_ADDR + MAT_SIZE
OUT_ADDR = KERN_ADDR + KERN_SIZE_ROUNDED

MAX_ERR = 10

def twos_complement_8bit(raw_val):
    val = raw_val & 0x7f
    if raw_val & 0x80 > 0:
        val -= 128
    return val

# usage check
print(len(argv), argv)
if len(argv) < 2:
    print(f"USAGE: {argv[0]} input_file input_rows input_cols kern_file kern_size output_file [step_size] [twos_complement] [skip_border]")
    exit()

# get input matrix
input_file = argv[1]
input_rows = int(argv[2])
input_cols = int(argv[3])
input_size = input_rows * input_cols
input_mem = None
with open(input_file, "rb") as f:
    input_mem = f.read(input_size)

# get kernel
kern_file = argv[4]
kern_rows = int(argv[5])
kern_size = kern_rows ** 2
hf_kern_rows = kern_rows >> 1
kern_mem = None
with open(kern_file, "rb") as f:
    kern_mem = f.read(kern_size)

# get output
output_file = argv[6]
output_mem = None
with open(output_file, "rb") as f:
    output_mem = f.read(input_size)

if not(input_mem and kern_mem and output_mem):
    print("Unable to load all data")
    exit()

step = 1
if len(argv) >= 8:
    step = int(argv[7])

twos_complement = True
if len(argv) >= 9:
    twos_complement = argv[8] == "1"

skip_border = False
if len(argv) >= 10:
    skip_border = argv[9] == "1"

print(f"Step: {step}, 2's complement: {twos_complement}, skip border check: {skip_border}")

###############################
##### CONSTRUCT ADDRESSES #####
###############################

def get_input_elem(r, c):
    return int(input_mem[r * input_cols + c])

def get_kern_elem(i):
    return twos_complement_8bit(int(kern_mem[i])) if twos_complement else int(kern_mem[i])

def get_output_elem(r, c):
    return int(output_mem[r * input_cols + c])

################
##### MAIN #####
################

print(f"Validating contents of {output_file} with {kern_rows}x{kern_rows} kernel.")
err_cnt = 0

def check(r, c, expected, err_cnt):
    # compare to stored value
    if (expected & 0xff != get_output_elem(r, c)):
        if err_cnt < MAX_ERR:
            print(f">>>ERROR: at row {r} and col {c}, expected {expected & 0xff}, found {get_output_elem(r, c)}")
            err_cnt += 1
        else:
            raise Exception("Maximum number of errors encountered")

    return err_cnt

for r in range(0, input_rows, step):
    for c in range(0, input_cols, step):
        # get expected value
        expected = 0
        if (r >= hf_kern_rows and r < input_rows-hf_kern_rows and c >= hf_kern_rows and c < input_cols-hf_kern_rows):
            kerni = 0
            for i in range(-hf_kern_rows, hf_kern_rows+1, 1):
                for j in range(-hf_kern_rows, hf_kern_rows+1, 1):
                    expected += get_input_elem(r+i, c+j) * get_kern_elem(kerni)
                    kerni += 1

            if skip_border:
                err_cnt = check(r, c, expected, err_cnt)

        if not(skip_border):
            err_cnt = check(r, c, expected, err_cnt)

if err_cnt > 0:
    raise Exception(f"{err_cnt} errors encountered in comparison")

print("Success!")

exit()
