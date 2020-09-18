---
title : "Eclipse with CMake project on windows"
description : "create an eclipse setup from CMake for embedded project"
tags : 
 - "eclipse"
 - "embedded"
date : "2020-09-12"
archives : "2020"
categories : 
 - "emmbeded"

menu : "no-main"
---

CMake is a powerful tool to manage c/c++ projects, and I prefer to use it in on my embedded projects also. Usually, the MCU has some communication with other processors (usually PC), and CMake also allows easy integration between both projects: MCU and HOST. For example, a shared source code that simultaneously able to recompile in both processors when any change occurs in these shared files.

Usually, I  work in a Linux environment in the terminal where everything is installed correctly in its place, and things work great.  Still, when I had to switch it to eclipse on windows environment, that was a challenging task. Hence, I describe here the stages that I had to do to import a CMake project from Linux to eclipse that run on windows. The first stage is to install the following software on windows.

* [arm tool chain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) 
* [gnu make tool](http://gnuwin32.sourceforge.net/packages/make.htm) - used by cmake and eclipse
* [cmake](https://cmake.org/)
* [jdk 11](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html) - used by eclipse
* [eclipse for mcu](https://gnu-mcu-eclipse.github.io/)

For convenience, it is better to install the software above in the global [path](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/) variable.

## CMake project
The CMake tools is a generator of build systems. It can create projects to different kinds of IDEs like eclipse and visual studio, and depend on a selected IDE; it makes appropriate project files.  CMake project s a sort of scripting language that defines the project files, compiler, flag, etc.'  For embedded projects, I usually maintain two sub-projects:
* embedded project
* PC project - includes unit tests, a library of communication, etc.'

The general template for such a project can have the following structure.
```bash
├── arm_app
│   ├── src
│   ├── bsp
│   └── CMakeLists.txt
├── CMakeLists.txt
├── shared
└── pc_app
    └── CMakeLists.txt
```

Each directory includes a nested *CMakeLists.txt* as it should be in *CMake* projects. The BSP directory usually should be taken from the chip (st, cypress, Atmel, etc.') provider, the src directory is the project itself, and its structure depends on the project. It may contain more subdirectories and libraries and more nested *CMakeLists.txt* files.

I have used the following CMake variable to skip compiler checks that may fail under windows.

```cmake
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
```

This variable setting is specific for the embedded cross compiler:

```cmake
SET(CMAKE_CROSSCOMPILING 1)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
```
and finaly this variabe to handle CMake error as reffers [here](https://stackoverflow.com/questions/10599038/can-i-skip-cmake-compiler-tests-or-avoid-error-unrecognized-option-rdynamic)
```cmake
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
```
### top project
The top *CMakeLists* contains the following content:
```cmake
cmake_minimum_required (VERSION 2.8)
SET(CMAKE_CONFIGURATION_TYPES "Debug;Release;MinSizeRel;RelWithDebInfo" CACHE STRING "" FORCE)
if (NOT CMAKE_BUILD_TYPE)
	set (CMAKE_BUILD_TYPE Debug CACHE STRING
         "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
         FORCE
    )
endif (NOT CMAKE_BUILD_TYPE)
set (CMAKE_USE_RELATIVE_PATHS True)\
add_subdirectory (${CMAKE_SOURCE_DIR}/arm_app )
add_subdirectory (${CMAKE_SOURCE_DIR}/pc_app )
SET(CMAKE_GENERATOR "Unix Makefiles")
project (top NONE)
```
It not a project, but it calls the other two sub-projects.

### pc application
For the pc application, we need *CMake* project. [Reffer](https://github.com/yairgd/atari) here for a simple project that I wrote, and it works with CMake.
The *shared* directory should contain source files which compiled on both systems: embedded and PC. Usually, these files relate to structures and code that both MCU and PC used for communication or any other shared data between the MCU and its host.

### embedded application
The *CMakeLists* of the arm application contains the path to arm compiler. If there is a global PATH variable that points to the compiler - The user is asked about it during the installation of the compiler - *COM_PATH*  can be lived empty. The *CON_EXT* includes the *exe* suffix in windows application. The following *CMakeLists.txt* has a linker configuration for arm cortex-m4.

```cmake
if (UNIX)
	set (COM_EXT "")
	set (COM_PATH  /path/to/arm-compiler)
	add_custom_target(flash
		#COMMAND ${OBJCOPY} -O ihex -R .eeprom $< $@       
		COMMAND echo "It can be replaced comand to flash bin to jtag"
	)
	set (unix_extra_define "-DCONFIG_VERSION")
	
else()
	set (COM_EXT ".exe")
	set (COM_PATH  "c:\path\to\arm-compiler")
endif()

set(CMAKE_CXX_COMPILER
	${COM_PATH}arm-none-eabi-g++${COM_EXT}
	) 
	
set(CMAKE_C_COMPILER
	${COM_PATH}arm-none-eabi-gcc${COM_EXT}
	)

set(CMAKE_ASM_COMPILER
	${COM_PATH}arm-none-eabi-gcc${COM_EXT}
	)


set(CMAKE_AR
	${COM_PATH}arm-none-eabi-ar${COM_EXT}
	)
# special settings for embedded compiler under windows
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
SET(CMAKE_CROSSCOMPILING 1)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
project (arm_app)

#version number
set (PROJECT_VERSION_MAJOR 1)
set (PROJECT_VERSION_MINOR 0)
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
	message("debug mode")
	set (CMAKE_C_FLAGS 
		" -mcpu=cortex-m4 -mfloat-abi=softfp -mfpu=fpv4-sp-d16 -mthumb ${CMAKE_C_FLAGS_DEBUG}" )

	set (CMAKE_CXX_FLAGS 
		" -mcpu=cortex-m4 -mfloat-abi=softfp -mfpu=fpv4-sp-d16 -mthumb ${CMAKE_CXX_FLAGS_DEBUG}  -fpermissive" )

endif (CMAKE_BUILD_TYPE STREQUAL "Debug") 

if (CMAKE_BUILD_TYPE STREQUAL "Release")
	message("debug mode")
	set (CMAKE_C_FLAGS 
		" -mcpu=cortex-m4 -mfloat-abi=softfp -mfpu=fpv4-sp-d16 -mthumb ${CMAKE_C_FLAGS_RELEASE}" )

	set (CMAKE_CXX_FLAGS 
		" -mcpu=cortex-m4 -mfloat-abi=softfp -mfpu=fpv4-sp-d16 -mthumb ${CMAKE_CXX_FLAGS_RELEASE}  -fpermissive" )
endif (CMAKE_BUILD_TYPE STREQUAL "Release") 

enable_language(ASM)
SET (ASM_OPTIONS "-x assembler-with-cpp")
SET(CMAKE_ASM_FLAGS "${CMAKE_C_FLAGS} ${ASM_OPTIONS}" )

include_directories(
	${CMAKE_SOURCE_DIR}/app
	${CMAKE_SOURCE_DIR}/bsp
	)

add_definitions( -D CY_CORE_ID=0 -D CY_PSOC_CREATOR_USED=1 -DCY8C6347BZI_BLD53 ${unix_extra_define})
set ( CMAKE_EXE_LINKER_FLAGS " -mcpu=cortex-m4 -mfloat-abi=softfp -mfpu=fpv4-sp-d16 -mthumb  -T ${CMAKE_SOURCE_DIR}/project/PSoC6/cy8c6xx7_cm4_dual.ld -specs=nano.specs -Wl,--gc-sections -g -ffunction-sections -ffat-lto-objects -e Reset_Handler")

add_subdirectory (${CMAKE_CURRENT_SOURCE_DIR}/bsp )
add_subdirectory (${CMAKE_CURRENT_SOURCE_DIR}/app )
```


## create an eclipse project
To create an eclipse project, we have to run the following code in windows command terminal:
```bash
cd c:\path\to\project
mkdir Debug
cmake -G "Eclipse CDT4 - Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_ECLIPSE_GENERATE_SOURCE_PROJECT=TRUE -DCMAKE_ECLIPSE_MAKE_ARGUMENTS=-j8 ..
```
As a result of that , cmake will create in the Debug directory files for eclipse roject like : *.project*,*.cproject*,*.setings*.
{{< figure src="/post/eclipse_for_embedded/run_cmake.png" title="create eclipse project" >}}

Now, in eclipse it has to import the project
{{< figure src="/post/eclipse_for_embedded/import_project.png" title="project import" >}}

click the left button and select Debug and press on *import*
{{< figure src="/post/eclipse_for_embedded/show_project.png" title="import the debug project" >}}

now, it can build, debug, and run it as any other eclipse project.
{{< figure src="/post/eclipse_for_embedded/import_debug_project.png" title="project ready to work" >}}

## Further Issues
* Debug tools using [xpack-openocd](https://xpack.github.io/openocd/releases/) for windows.  To install, follow that [reference](https://gnu-mcu-eclipse.github.io/debug/openocd/).
* Freertos thread awerness tools from [nxp](https://mcuoneclipse.com/2016/07/06/freertos-kernel-awareness-for-eclipse-from-nxp/)


## References
[1] [eclipse for mcu](https://gnu-mcu-eclipse.github.io/)

