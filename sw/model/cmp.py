
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

def build_mat_addr(r, c):
    return MAT_ADDR + r * MAT_COLS + c

def build_kern_addr(i):
    return KERN_ADDR + i

def build_out_addr(r, c):
    return OUT_ADDR + r * MAT_COLS + c

def twos_complement_8bit(raw_val):
    val = raw_val & 0x7f
    if raw_val & 0x80 > 0:
        val -= 128
    return val

if len(argv) < 2:
    print(f"USAGE: {argv[0]} mem_file kern_size step_size")
    exit()

mem_file = argv[1]
kern_rows = int(argv[2])
kern_size = kern_rows ** 2
hf_kern_rows = kern_rows >> 1

step = 1
if len(argv) == 4:
    step = int(argv[3])

with open(mem_file, "rb") as f:
    arr = f.read()
    
    print(f"Validating contents of {mem_file} with {kern_rows}x{kern_rows} kernel.")
    print("Kernel:", " ".join([str(twos_complement_8bit(int(arr[build_kern_addr(i)]))) for i in range(kern_size)]))
    
    err_cnt = 0
    for r in range(0, MAT_ROWS, step):
        for c in range(0, MAT_COLS, step):
            # get expected value
            expected = 0
            if (r >= hf_kern_rows and r < MAT_ROWS-hf_kern_rows and c >= hf_kern_rows and c < MAT_COLS-hf_kern_rows):
                kerni = 0
                for i in range(-hf_kern_rows, hf_kern_rows+1, 1):
                    for j in range(-hf_kern_rows, hf_kern_rows+1, 1):
                        expected += int(arr[build_mat_addr(r+i, c+j)]) * \
                            twos_complement_8bit(int(arr[build_kern_addr(kerni)]))
                        kerni += 1

            # compare to stored value
            stored = arr[build_out_addr(r, c)]

            if (expected & 0xff != stored):
                if err_cnt < MAX_ERR:
                    print(f">>>ERROR: at row {r} and col {c}, expected {expected}, found {stored}")
                    err_cnt += 1
                else:
                    raise Exception("Maximum number of errors encountered")

    if err_cnt > 0:
        raise Exception(f"{err_cnt} errors encountered in comparison")
    
    print("Success!")
    
    exit()
