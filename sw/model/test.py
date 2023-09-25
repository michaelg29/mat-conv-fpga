
from sys import argv

def twos_complement_8bit(raw_val):
    val = raw_val & 0x7f
    if raw_val & 0x80 > 0:
        val -= 128
    return val

if len(argv) == 19:
    vals = [*[int(arg, 16) for arg in argv[1:10]], *[twos_complement_8bit(int(arg, 16)) for arg in argv[10:]]]
    res = 0
    for i in range(9):
        print(f"{argv[1+i]}*{argv[10+i]} = {vals[0+i]}*{vals[9+i]} = {vals[0+i] * vals[9+i]}")
        res += vals[0+i] * vals[9+i]
    
    res &= 0xff
    print(res, hex(res))
else:
    print(f"USAGE: {argv[0]} hex(a[0]) ... hex(a[8]) hex(b[0]) ... hex(b[8])")
    print("    Computes the dot product of two 9-element vectors. Vector A has unsigned 1-byte elements and vector B has signed 1-byte values. All values should be passed as hex.")
