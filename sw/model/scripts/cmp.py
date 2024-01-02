
from sys import argv

MAX_ERR = 10

# class to abstract kernel encodings
class kern_encodings:

    Q0_8 = "Q0_8"   # Unsigned Q0.8
    RAW = "RAW"     # raw
    SQ0_7 = "SQ0_7" # Signed Q0.7
    TWOS = "TWOS"   # Two's complement
    
    # validate selected encoding method
    def parse(encoding):
        encodings = [kern_encodings.Q0_8, kern_encodings.RAW, kern_encodings.SQ0_7, kern_encodings.TWOS]
        if encoding not in encodings:
            raise Exception(f"Invalid encoding {encoding}, accepted are {encodings}")
            
        return encoding
        
    def decode(raw_int, encoding, msb=8):
        if encoding == kern_encodings.Q0_8:
            return float(raw_int) * (2 ** -8)
        elif encoding == kern_encodings.RAW:
            return raw_int
        elif encoding == kern_encodings.SQ0_7:
            add_factor = -1 if (raw_int & 0x80) > 0 else 0
            return (float(raw_int & 0x7f) * (2 ** -7)) + add_factor
        elif encoding == kern_encodings.TWOS:
            add_factor = -(2 ** msb) if (raw_int & 2 ** msb) else 0
            return int(raw_int & ((2 ** msb) - 1)) + add_factor
        
        return raw_int
    
if __name__ == "__main__":

    # usage check
    if len(argv) < 8:
        print(f"USAGE: {argv[0]} input_file input_rows input_cols kern_file kern_size kern_encoding output_file [step_size [do_round]]")
        exit()

    # get input matrix
    input_file = argv[1]
    input_rows = int(argv[2])
    input_cols = int(argv[3])
    input_size = input_rows * input_cols
    input_mem = None
    with open(input_file, "rb") as f:
        input_mem = list(f.read(input_size))
        for i in range(input_size):
            input_mem[i] = int(input_mem[i])

    # get kernel
    kern_file = argv[4]
    kern_rows = int(argv[5])
    kern_encoding = kern_encodings.parse(argv[6])
    kern_size = kern_rows ** 2
    hf_kern_rows = kern_rows >> 1
    kern_mem = None
    with open(kern_file, "rb") as f:
        kern_mem = list(f.read(kern_size))
        for i in range(kern_size):
            kern_mem[i] = kern_encodings.decode(int(kern_mem[i]), kern_encoding)

    # get output
    output_file = argv[7]
    output_mem = None
    with open(output_file, "rb") as f:
        output_mem = f.read(input_size)

    if not(input_mem and kern_mem and output_mem):
        raise Exception("Unable to load all data")

    step = 1
    if len(argv) >= 9:
        step = int(argv[8])

    do_round = True
    if len(argv) >= 10:
        do_round = argv[9] == "1"

    print(f"Step: {step}, rounding: {do_round}")

    ###############################
    ##### CONSTRUCT ADDRESSES #####
    ###############################

    def get_input_elem(r, c):
        if r < 0 or r >= input_rows or c < 0 or c >= input_cols:
            return 0
        return int(input_mem[r * input_cols + c])

    def get_kern_elem(i):
        if i < 0 or i >= kern_size:
            return 0
        
        return kern_mem[i]

    def get_output_elem(r, c):
        return int(output_mem[r * input_cols + c])

    ################
    ##### MAIN #####
    ################

    print(f"Validating contents of the {input_rows}x{input_cols} matrix in {output_file} with a {kern_rows}x{kern_rows} kernel.")
    err_cnt = 0

    def check(r, c, expected, err_cnt):
        # compare to stored value
        #print(f"at row {r} and col {c}, expected {hex(expected & 0xff)[2:]}, found {hex(get_output_elem(r, c))[2:]}")
        if (expected & 0xff != get_output_elem(r, c)):
            if err_cnt < MAX_ERR:
                print(f">>>ERROR: at row {r} and col {c}, expected {hex(expected & 0xff)[2:]}, found {hex(get_output_elem(r, c))[2:]}")
                err_cnt += 1
            else:
                raise Exception("Maximum number of errors encountered")

        return err_cnt

    for r in range(0, input_rows, step):
        for c in range(0, input_cols, step):
            expected = 0
            kerni = 0
            for i in range(-hf_kern_rows, hf_kern_rows+1, 1):
                for j in range(-hf_kern_rows, hf_kern_rows+1, 1):
                    expected += get_input_elem(r+i, c+j) * get_kern_elem(kerni)
                    kerni += 1

                # round and truncate
                if do_round:
                    pass

            # round and truncate
            if do_round:
                pass

            if c < 1918:
                err_cnt = check(r, c, int(expected), err_cnt)

    if err_cnt > 0:
        raise Exception(f"{err_cnt} errors encountered in comparison")

    print("Success!")

    exit()
