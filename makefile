
all: analyze

# -------------------------------------------------------------------
# <CUSTOMIZE AREA>
# -------------------------------------------------------------------

# Input files:

ifdef SRC_DIR
    # if a list of source code directories is given by $(SRC_DIR)
    # e.g. make SRC_DIR=src
    # then add all *.c files in those directories
    SRC_FILES := $(foreach dir, $(SRC_DIR), $(wildcard $(dir)/*.c))
endif

# Default: include all *.c files in the src directory
SRC_FILES ?= $(wildcard src/*.c)

# Another option: add individual list of files
# SRC_FILES += src2/evmesh.c src2/hamming.c
# Another option: add everything from a single source code directory
# SRC_FILES += $(wildcard src/*.c)

# Default: use "include/" as default include directory:
INCLUDE_PATH ?= -I"include"
# Add include directories with:
# INCLUDE_PATH += -I"include2"


# Output files:
build_directory := build
output_cgraph := stack-usage-log.cgraph
output_su := stack-usage-log.su
output_csv ?= stack-usage.csv
output_json ?= stack-usage.json

# Optional CFLAGS:
CFLAGS ?= -O0

CC ?= $(TOOLCHAIN)gcc

# -------------------------------------------------------------------
# </CUSTOMIZE AREA>
# -------------------------------------------------------------------

# Debug makefile by setting to an empty string
Q ?= @

# Required compiler CFLAGS for this makefile (don't touch)
# Include dependencies (i.e. .h files)
# -MMD: tell GCC to create dependency .d files
# -MP: These dummy rules work around errors make gives if you remove header
#      files without updating the Makefile to match.
#  With -include $(c_deps) include those generated .d files here in the makefile
CFLAGS += -MMD -MP
# Compile the source files using the flags *-fstack-usage* and
# *-fdump-ipa-cgraph* for GCC to get the information about stack usage and
# callgraph for the analysis python script.
# The object file is actually a byproduct
# e.g.  gcc -fstack-usage -fdump-ipa-cgraph -o example.o -c example.c
CFLAGS += -fstack-usage -fdump-ipa-cgraph
# Let the build fail if alloca is used:
CFLAGS += -Walloca -Werror=alloca
# Let the build fail if variable length arrays are used:
CFLAGS += -Werror=vla

# extract source directories from sources files:
source_dirs := $(sort $(dir $(SRC_FILES)))
VPATH += $(source_dirs)
# collect the pure file names without the path (file1.c file2.c ...)
source_file_names = $(notdir $(SRC_FILES))
# replace .c with .o for object file names
obj_file_names = $(source_file_names:%.c=%.o)
# add the build directory path
obj_files = $(addprefix $(build_directory)/,$(obj_file_names))
# add .d dependency files to the build directory
c_deps = $(obj_files:%.o=%.d)
-include $(c_deps)

analyze: $(obj_files)
# @echo 'source file names: ' $(source_file_names)
# @echo 'obj filenames: ' $(obj_file_names)
	$(Q)echo 'Input source files:' $(SRC_FILES)
# $(Q)echo 'Object files:' $(obj_files)
	$(Q)find $(build) -name '*.cgraph' | grep -v stack-usage-log | xargs cat > $(output_cgraph)
	$(Q)find $(build) -name '*.su'     | grep -v stack-usage-log | xargs cat > $(output_su)
	$(Q)echo 'Output files:' $(output_csv), $(output_json)
	$(Q)echo
	$(Q)echo 'Calculated worst-case stack usage in bytes:'
	$(Q)python stack-usage.py --warn on --csv $(output_csv) --json $(output_json)
# fail the build if we detect recursion (! to invert return code)
	$(Q)! cat $(output_csv) | grep "recursion detected"
# fail the build if we detect a non-static and non-bounded function in the .su input (keyword "dynamic" at end of .su file line)j
	$(Q)! cat $(output_su) | grep "dynamic$$"

# VPATH recreates the full path of the .c input
$(build_directory)/%.o: %.c
	@echo 'CC' $< '->' $@
	$(Q)$(CC) $(CFLAGS) -c "$<" -o "$@" $(INCLUDE_PATH)

clean:
	rm -f $(build_directory)/*.o
	rm -f $(build_directory)/*.d
	rm -f $(build_directory)/*.su
	rm -f $(build_directory)/*.cgraph
	rm -f $(output_cgraph)
	rm -f $(output_su)
	rm -f $(output_csv)
	rm -f $(output_json)

.PHONY: all clean

