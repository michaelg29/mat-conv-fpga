SystemC Windows install instructions


Pre-req:
-MSYS2: https://code.visualstudio.com/docs/cpp/config-mingw
-CMake


/***** BUILDING AND INSTALLING SYSTEMC *****/

1-Download systemc repo (https://github.com/accellera-official/systemc/tree/master)
2-Go to the repo directory
3-Create a folder called "build"
4-Open cmake-gui. Set the sources files path to the repo and the build path to the build folder
5-Click configure (select MinGW as the generator with native compiler)
NOTE: to reconfigure the generator, click File -> delete cache and then click configure again
6-In the GUI, change the following options:
	-C standard: 11

7-Click generate
8-Go to the build folder and open the command line
9-Enter "make all" in the command line
NOTE: if you get an error such as:
"
C:\Users\Jacoby\Desktop\Github\systemc\src\sysc\packages\qt\md\iX86_64.s:78: Error: junk at end of line, first unrecognized character is `-'
make[2]: *** [src\CMakeFiles\systemc.dir\build.make:1365: src/CMakeFiles/systemc.dir/sysc/packages/qt/md/iX86_64.s.obj] Error 1
make[1]: *** [CMakeFiles\Makefile2:717: src/CMakeFiles/systemc.dir/all] Error 2
make: *** [Makefile:135: all] Error 2
"
Go in the file "iX86_64.s.obj" and comment out this part:
"
#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
"
Then make sure to call "make clean" before recalling "make all"

10-Open a command line with admin privileges
11-Navigate to the build folder
12-Call "make install" to install SystemC



/***** RUNNING AN APPLICATION *****/

In VSCode, the json files are already configured. Therefore, simply open the main.cpp file you want to run and do "Run"
NOTE: you can change <MEMROY_FILE> and <KERNEL_SIZE> in the launch.json file (in the field "args")