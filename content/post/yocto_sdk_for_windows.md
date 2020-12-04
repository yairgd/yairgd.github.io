---
title: "Install embedded Linux toolchain on windows"
description: "Howto build and compile Linux embedded toolchain for windows using Yocto and install it on eclipse or visual studio"
tags : 
 - "linux"
 - "yocto"

date : "2020-11-25"
archives : "2020"
categories : 
 - "linux"
 - "embedded"

draft: false
menu : "no-main"
---
The toolchain for embedded Linux should be matched for the target image, and that is why we can't just find and download it from somewhere. Therefore, we should be it. This is a tutorial on how to build and install YOCTO SDK on a windows machine. This allows developing embedded Linux on windows using eclipse or even visual studio.

## Setup YOCTO build
If you already have a YOCTO build, you need to make the following simple steps:

add to conf/local.con the following 2 lines:
```bash
SDKMACHINE="x86_64-mingw32"
SDK_ARCHIVE_TYPE = "zip"
```

Download and install meta-mingw layer. Just add the following line to your *conf/bblayer.conf*. Just make sure that the branch of [meta-mingw](http://git.yoctoproject.org/cgit.cgi/meta-mingw) layer corresponds with the branch of the YOCTO installation.
```bash
BBLAYERS =+ "/path/to/meta-mingw"
```

Now it just has to type *bitbake meta-toolchain*, and the magic should happen.


## What next
* if everything was good. The toolchain will be deployed to *build/tmp/deploy/sdk*.
* To embedded the toolchain in IDEs like eclipse and qt-creator. I usually work with CMake projects, and it is easy to port a CMake project for both IDEs on windows. See [post]({{< ref  path="post/eclipse_for_embedded.md" >}}) the I wrote on it.
* Using visual studio. See this [ref](https://www.yoctoproject.org/learn-items/using-vs-and-vs-code-for-embedded-c-c-development/).

## trouble shout
When using the poky distribution like I did [here]({{< ref  path="post/install_linux_on_microzed.md" >}}) there were no problems. I worked with the *zues* branch, and everything was by the book.

When I work with yocto distribution for [stm32mp](https://www.st.com/en/embedded-software/stm32mp1distrib.html) I had to work around some issues. I think it relates to the way the ST defines its yocto distribution.

* As a result of the folloing error message.
```bash
ERROR: Task do_install in virtual:nativesdk:/path/to/yocto/layers/openembedded-core/meta/recipes-core/glibc/glibc-locale_2.31.bb depends upon non-existent task do_stash_locale in /path/yo/yocto/layers/meta-openembedded/meta-mingw/recipes-devtools/mingw-w64/nativesdk-mingw-w64-runtime_6.0.0.bb
ERROR: Command execution failed: 1`
```

add the following lines to this file [nativesdk-mingw-w64-runtime_6.0.0.bb](http://git.yoctoproject.org/cgit.cgi/meta-mingw/tree/recipes-devtools/mingw-w64/nativesdk-mingw-w64-runtime_6.0.0.bb?h=dunfell) 

```bash
addtask do_stash_locale after do_install before do_populate_sysroot do_package
do_stash_locale() {
}
```

* Added the disabling of TUI option in GDB (by *--diable-tui*) during the building of GDB  at this file [gdb-cross-canadian_%.bbappend](http://git.yoctoproject.org/cgit.cgi/meta-mingw/tree/recipes-devtools/gdb/gdb-cross-canadian_%25.bbappend?h=dunfell). For some reason that I don't understand, the TUI option was probably added in the ST yocto distribution.
```bash
EXTRA_OECONF_append_sdkmingw32 = "--disable-tui --without-curses --without-system-readline --with-python=no"
```

* In this file *st-machine-common-stm32mp.inc* I had to disable some native SDK packages that were filed during the compilation.
```bash
.
ST_DEPENDENCIES_BUILD_FOR_SDK_append = " nativesdk-openssl-dev "
.
.
TOOLCHAIN_HOST_TASK_append = " ${ST_TOOLS_FOR_SDK} "
TOOLCHAIN_HOST_TASK_append = " ${ST_DEPENDENCIES_BUILD_FOR_SDK} "
.
.
```




