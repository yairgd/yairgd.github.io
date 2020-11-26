---
title: "Install ebdedded linux toolchain on windows"
description: "Howto build and compile linux embedded toolchain for windows using Yocto and install it on eclipse or visual studio"
tags : 
 - "linux"
 - "yocto"

date : "2020-11-25"
archives : "2020"
categories : 
 - "linux"
 - "embedded"

draft: true
menu : "no-main"
---
The toolchain for embdedded linux should be matche for yhe target image and that is why we can't just find and download it from some where. Therefore, we should be it. this is  tutorial how to build and install yocto SDK on windows machine. This to allow developing embbeded linux on windows using eclipse or event visual studio.

## Setup yocto build
If you allready has a Yocto build you just need to make the following simple steps:

add to conf/local.con the following 2 lines:
```bash
SDKMACHINE="x86_64-mingw32"
SDK_ARCHIVE_TYPE = "zip"
```

download and install meta-mingw layer. Just add the folloing line to your *conf/bblayer.conf*. Just make sure that the brach of [meta-mingw](http://git.yoctoproject.org/cgit.cgi/meta-mingw) layer corresponds with the branch of the yocto installation.
```bash
BBLAYERS =+ "/path/to/meta-mingw"
```

Now it just has to type *bitbake meta-toolchain* and the magic should happen.


## What next
* if every thinkg was good. The tool chain will be deploy to *build/tmp/deploy/sdk*.
* To embedded the toolchain in IDEs like eclipse and qt-creator. I useually work with cmake projects and it is easy to port a cmake project for both IDEs on windows. See [post]({{< ref  path="post/eclipse_for_embedded.md" >}}) the I wrote on it.
* Using visual studio. See this [ref](https://www.yoctoproject.org/learn-items/using-vs-and-vs-code-for-embedded-c-c-development/).

## trouble shout
When using the poky disribution like I did [here]({{< ref  path="post/install_linux_on_microzed.md" >}}) there were now problems. I wrokred with zues brch and every thing was by the book.

When I work with yocto disribution for [stm32mp](https://www.st.com/en/embedded-software/stm32mp1distrib.html) I had to work arround some issues. I think it relates to the way the ST defines its yocto disribution.

* As a result of the folloing error message.
```bash
ERROR: Task do_install in virtual:nativesdk:/path/to/yocto/layers/openembedded-core/meta/recipes-core/glibc/glibc-locale_2.31.bb depends upon non-existent task do_stash_locale in /path/yo/yocto/layers/meta-openembedded/meta-mingw/recipes-devtools/mingw-w64/nativesdk-mingw-w64-runtime_6.0.0.bb
ERROR: Command execution failed: 1`
```

add the folling lines to this file [nativesdk-mingw-w64-runtime_6.0.0.bb](http://git.yoctoproject.org/cgit.cgi/meta-mingw/tree/recipes-devtools/mingw-w64/nativesdk-mingw-w64-runtime_6.0.0.bb?h=dunfell) 

```bash
addtask do_stash_locale after do_install before do_populate_sysroot do_package
do_stash_locale() {
}
```

* Added the disabling of TUI option in GDB (by *--diable-tui*) during the building of GDB  at this file [gdb-cross-canadian_%.bbappend](http://git.yoctoproject.org/cgit.cgi/meta-mingw/tree/recipes-devtools/gdb/gdb-cross-canadian_%25.bbappend?h=dunfell). From some reason that I don't understand, the TUI option was probebly added in the ST yocto disribution.
```bash
EXTRA_OECONF_append_sdkmingw32 = "--disable-tui --without-curses --without-system-readline --with-python=no"
```

* In this file *st-machine-common-stm32mp.inc* I had to diable some nativesdb packages that were filed during the compilation.
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



## References
[[1] https://www.kernel.org/doc/html/v4.13/driver-api/uio-howto.html](https://www.kernel.org/doc/html/v4.13/driver-api/uio-howto.html)  

