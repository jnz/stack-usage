# Stack Usage

## Intro

    "With experience, one learns the standard, scientific way to compute the proper
     size for a stack: Pick a size at random and hope."
        -- Jack Ganssle. The Art of Designing Embedded Systems. Newnes, 2008

The purpose of this python script is to extract information about the **stack
usage** and **callgraphs** of your C/C++ program just by using the standard GCC
toolchain (native or as cross-compiler).

To analyze all source code files in the *src/* directory just run:

    make

To analyze a bunch of files from another directory:

    make SRC_DIR=some_source_directory

To analyze a set of specific files:

    make SRC_FILES="src/file_a.c src/file_b.c"

By default the *include/* directory is scanned for header files.
Specify other include directories with

    make INCLUDE_PATH=-I"some_other_include"

# Output

The output will be a CSV file and a dictionary in JSON format.

stack-usage.csv

    184;foobar/16 foo/160 bar/8
    24;foobar/16 bar/8
    184;main/16 foo/160 bar/8

stack-usage.json

    {
        'callStack':'',
        'maxSize':192,
        'size':0,
        'name':'',
        'children':[
            {
                'callStack':'main/16',
                'maxSize':192,
                'size':16,
                'name':'main',
                'children':[
                    {
                        'callStack':'main/16 foo/160',
                        'maxSize':192,
                        'size':176,
                        'name':'foo',
                        'children':[
                            {
                                'callStack':'main/16 foo/160 bar/16',
                                'maxSize':192,
                                'size':192,
                                'name':'bar',
                                'children':[
                                ]
                            }
                        ]
                    }
                ]
            }
        ]
    }


## Limitations

Of course there are some limitations. For instance **function pointers** cannot
be resolved as the compiler itself has no information about how they will be
executed during runtime. Next is **recursion**. Although it can be detected at
compile time in general we never know how deep the nesting is at runtime. There
is another limitation which is **duplicate functions**. As all data is
currently collected into one file the python script can currently not resolv
whether a function comes from source code A or B. However in a good project you
shall not find two different functions in multiple files having the same name.
So this usually shouldn't be an issue. The last thing to mention are
**libraries**. We can only assume a stack usage of zero for 3rd party functions
and internal functions provided by the runtime environment as we don't know
anything about code we did not compile ourselves.

In a nutshell, avoid:

    - Recursion
    - alloca function
    - Function pointers
    - Duplicate function names
    - Library functions


## Interrupts

If you have interrupts, you can perform the analysis manually in two steps:

    worst-case depth = depth of main + total depth of all interrupts

# Inner workings

Compile your source files using the flags *-fstack-usage* and
*-fdump-ipa-cgraph* for GCC to get the information about stack usage and
callgraph.

    gcc -fstack-usage -fdump-ipa-cgraph -o example example.c

Collect the data to process this information.

    find . -name '*.cgraph' | grep -v stack-usage-log | xargs cat > stack-usage-log.cgraph
    find . -name '*.su'     | grep -v stack-usage-log | xargs cat > stack-usage-log.su

Run the script to see your stack usage.

    python stack-usage.py --csv stack-usage.csv --json stack-usage.json

## Planned features

    - clang -S -emit-llvm SourceFile.c -o - | opt -analyze -print-callgraph
    - generate json to dot output

# License

Heavily based on:
https://github.com/sharkfox/stack-usage by Enrico May (GPL-3 License)

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, see http://www.gnu.org/licenses/.

