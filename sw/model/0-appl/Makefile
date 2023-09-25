
#####################
##### Variables #####
#####################
MEM_FILE     = mem_init
KERNEL_SIZE  = 3
DO_RANDOM    = 0

#########################
##### Configuration #####
#########################

# programs
CXX              ?=g++
TIME_EXEC        ?=/usr/bin/time
TARGET_ARCH      ?= linux64
ifneq (,$(strip $(TARGET_ARCH)))
ARCH_SUFFIX      ?= -$(TARGET_ARCH)
endif

# basic SystemC directories
SYSTEMC_HOME     ?= $(SYSTEMC)
SYSTEMC_INC_DIR  ?= $(SYSTEMC_HOME)/include
SYSTEMC_LIB_DIR  ?= $(SYSTEMC_HOME)/lib$(ARCH_SUFFIX)

# basic check for SystemC directory
ifeq (,$(wildcard $(SYSTEMC_HOME)/.))
$(error SYSTEMC_HOME [$(SYSTEMC_HOME)] is not present. \
        Please update the variable SYSTEMC_HOME)
endif
ifeq (,$(wildcard $(SYSTEMC_INC_DIR)/systemc.h))
$(error systemc.h [$(SYSTEMC_INC_DIR)] not found. \
        Please update the variable SYSTEMC_HOME)
endif
ifeq (,$(wildcard $(SYSTEMC_LIB_DIR)/libsystemc*))
$(error SystemC library [$(SYSTEMC_LIB_DIR)] not found. \
        Please update the variable TARGET_ARCH)
endif

# compiler flags
CFLAGS = -g3
IFLAGS = -I../include -isystem $(SYSTEMC_INC_DIR)
LFLAGS = -lsystemc -lm -L$(SYSTEMC_LIB_DIR)
DEPS   = $(wildcard *.h) $(wildcard ../include/*.h)
SRCS   = $(wildcard *.cpp) $(wildcard ../src/*.cpp)
OBJS   = $(SRCS:.cpp=.o)

##########################################
##### Process command line arguments #####
##########################################

###################
##### Targets #####
###################

%.o: %.cpp $(DEPS)
	$(CXX) -c -o $@ $< $(CFLAGS) $(IFLAGS)

system: $(OBJS)
	$(CXX) -o $@ $^ $(CFLAGS) $(LFLAGS)

run: system
	./system $(MEM_FILE) $(KERNEL_SIZE) $(DO_RANDOM)

.PHONY: clean

clean:
	rm -f $(OBJS) system
