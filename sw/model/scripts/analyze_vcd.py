
from sys import argv
import matplotlib.pyplot as plt

# parse numerical value from trace file
def parse_num(string):
    if string.startswith("b"):
        return int(string[1:], 2)
    elif string.startswith("h"):
        return int(string[1:], 16)
    return int(string)

# types of functions
class function_types:
    PLOT = "plot"

    def get_list():
        return [function_types.PLOT]

# usage check
if len(argv) < 4:
    print(f"USAGE: {argv[0]} <vcd_file> <function> <signals> ...")
    exit()

# parse cmd line arguments
input_file = argv[1]
function = argv[2]
signals = argv[3:]

# validate cmd line arguments
if function not in function_types.get_list():
    raise Exception(f"Invalid function: {function}")

# get dumpvar names
tracknames = []
tracknames_mapping = {}
module_names = []
with open(input_file, "r") as f:
    for line in f:
        if line.startswith("$scope module"):
            # push to module name stack
            split_line = line.split()
            module_names.append(split_line[2])
                
        elif line.startswith("$var"):
            split_line = line.split()
            # check for signal name
            sig_name = ".".join(module_names) + "." + split_line[4]
            if sig_name in signals:
                print(f"Mapped {sig_name} to {split_line[3]}")
                tracknames.append(split_line[3])
                tracknames_mapping[split_line[3]] = sig_name
        
        elif line.startswith("$upscope"):
            # pop from module name stack
            module_names.remove(module_names[-1])
            
        elif line.startswith("$enddefinitions"):
            break
        
if not(tracknames) or len(tracknames) == 0:
    raise Exception("Invalid file or no variables found to track.")

if function == function_types.PLOT:
    # initialize lists
    times = []
    data_tracking = []
    for name in tracknames:
        data_tracking.append([])
        
    with open(input_file, "r") as f:
        t = 0
        in_dump_section = False
        for line in f:
            if in_dump_section:
                split_line = line.split()
                try:
                    i = tracknames.index(split_line[1])
                    data_tracking[i].append(parse_num(split_line[0]))
                except:
                    pass
                # if split_line[1] in tracknames:
                    
        
            if line.startswith("$dumpvars"):
                in_dump_section = True
                times.append(t)
            if line.startswith("#"):
                in_dump_section = True
                times.append(int(line[1:]))
                
                # synchronize all lists
                for track in data_tracking:
                    while len(track) != len(times):
                        track.append(track[-1])
                
    plt.plot(times, data_tracking[0])            
    
    plt.show()
