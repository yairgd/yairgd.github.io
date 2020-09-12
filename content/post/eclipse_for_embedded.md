---
title: "Ecpise with cmake project on windows"
description: "create an eclipse setup from cmake for embbeded projects "
tags : 
- "eclipse"
- "emmbeded"

date : "2020-09-12"
archives : "2020"
categories : 
- "emmbeded"

menu : "no-main"
---
CMake is a powerfull tool to manage c/c++ projects and I preffer to use in on my embbeded projects also. Usually I work in linux enviementn in terminal  and Iin linux enviroments , every thing installed in the place and thing works great, but when I had to switch it to eclipse on windows envement ,that  was a changled task  so I describe here the stages that I had to make in order import my cmkae forject from linux to windos based on eclipse. The first stage is to instal the following softawer on windows.

* [arm tool chain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) 
* [gnu make tool](http://gnuwin32.sourceforge.net/packages/make.htm) - used by cmake and eclipse
* [cmake](https://cmake.org/)
* [jdk 11](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html) - used by eclipse
* [eclipse for mcu](https://gnu-mcu-eclipse.github.io/)

For convinece , it is better to install the software above in the global [path](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/) vriable.

## cmake project
The cmake tools is a generator of build systems. It  can create projects to diffetents kinds of IDEs like eclise and visual studio and depend on a selected IDE it creates a propriate prjectsfiles.  It is based on configuration file named *CMakeLists.txt* - it is   a kind of scripting language that defines the project files , compiler  , flag etc'.  For embbeded projects I usually matins 2 projects:

* embbeded project
* PC project - includes unit tests, library of commnication etc'

The general template for such  project can have the following  structute.
```bash
├── arm_app
│   ├── src
│   ├── bsp
│   └── CMakeLists.txt
├── CMakeLists.txt
├── common
└── pc_app
    └── CMakeLists.txt
```

Each directory includes a nested *CMakeLists.txt* as it shoud be in *cmake* projects. The bsp dirctory usually shlud be taken from the chip (st,cypress,atmel etc') provider, the src directory is the projectsis self and its structre depend in the projects and may contain more sub directories and libraries. The common directory shpould contain source files that compiled on both system: embedded and PC. Usually these fle relate to commnication structure that both CPUs used for cominication or any other common data.
I have used the following cmake vairbale to skip compiler checks that may fail under windows.
```cmake
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
```

This variable setting are specific for embedded cross complier:
```cmake
SET(CMAKE_CROSSCOMPILING 1)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
```
and finaly this variabe to handle cmakle error as reffers [here](https://stackoverflow.com/questions/10599038/can-i-skip-cmake-compiler-tes    ts-or-avoid-error-unrecognized-option-rdynamic)
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
It not a project , but it calls the other two subdirectory with the projects
### pc application
For the pc application we need *cmake* project. [Reffer](http://derekmolloy.ie/hello-world-introductions-to-cmake/) here for more details. The common dircory should contain files that are also used in the embbeded proccessor. For example , it shoud contain a source file with commnication protocol, like structure that both sides use it.

### embbeded project
The the *CMakeLists* of the arm appclication contains the path to arm compiler. If the path is written in the PATH variable , *COM_PATH*  can be lived empty. The *CON_EXT* includes the *exe* suffix in windows application. The folloing *CMakeLists.txt* has linker configuration for arm coretx-m4.


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


## create eclipse project
To create an eclipse project we have to run the following code in windows command terminl:
```bash
cd c:\path\to\project
mkdir Debug
cmake -G "Eclipse CDT4 - Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_ECLIPSE_GENERATE_SOURCE_PROJECT=TRUE -DCMAKE_ECLIPSE_MAKE_ARGUMENTS=-j8 ..
```
As a result of that , cmake will create in the Debug directory files for eclipse roject like : *.project*,*.cproject*,*.setings*.
{{< figure src="/post/eclipse_for_embedded/run_cmake.png" title="create eclipse project" >}}

Now, in eclipse it has to import the project
{{< figure src="/post/eclipse_for_embedded/import_project.png" title="project import" >}}

select Debug and click on the eftbutton and press on *import*
{{< figure src="/post/eclipse_for_embedded/show_project.png" title="import the debug project" >}}

now, it can bulid,debug and run it as any other eclipse project.
{{< figure src="/post/eclipse_for_embedded/import_debug_project.png" title="project redy to work" >}}

## further issues

## References

