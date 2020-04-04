---
title: "Simple Hello World application using qt5 for embedded Linux device."
description: "Simple Hello World application using qt5 for embedded Linux device."
draft: false
tags : 
 - "linux"
 - "qt5"
 - "embedded"
date : "2020-04-01"
archives : "2020"
categories : 
 - "linux"
 - "qt5"

menu : "no-main"
---
This post presents a simple example of how to create a qt5 application for a Linux embedded device that runs Wayland or x-server. I'm using Yocto build system. I already have a BSP for IMX8 + toolchain so. I just have to install qt5 on it. In the time that I wrote this page. See [here](https://github.com/varigit/variscite-bsp-platform) a reference to use Yocto project.

## bug workaroud
I worked with *sumo* branch and had to do some work around over three bugs that I found during the compilation of qt5. 
1.  apply this [patch](https://codereview.qt-project.org/c/qt/qtbase/+/245425/3/src/corelib/global/qrandom.cpp#b219)
2.  apply changes to this file: qfilesystemengine_unix.cpp. I found it under *tmp/work/x86_64-linux/qtbase-native/5.10.1+gitAUTOINC+6c6ace9d23-r0/git/src/corelib/io/qfilesystemengine_unix.cpp*.
    * line 101,107 - remove the static keyword, since the function already defined as an extern in another file.
    *  line 106 -removed, is made a multiplay definition compilation error message. 


## install qt5-layer 
The layer [meta-qt5](https://github.com/meta-qt5) should defined on *local/conf/bblayers.conf* and the following command should run under the build directory:

```bash
bitbake bitbake meta-toolchain-qt5
```

to install to sdk type under the build directory:
```bash
sudo  ./tmp/deploy/sdk/fsl-imx-xwayland-glibc-x86_64-meta-toolchain-qt5-aarch64-toolchain-4.14-sumo.sh
```

when you do it, you can test it:
```bash
$  . /opt/fsl-imx-xwayland/4.14-sumo/environment-setup-aarch64-poky-linux
$ echo $CC
aarch64-poky-linux-gcc --sysroot=/opt/fsl-imx-xwayland/4.14-sumo/sysroots/aarch64-poky-linux
```


## Simple application
I created a straightforward application using [qt-creator](https://doc.qt.io/qt-5/topics-app-development.html), and I had to run this command:
```bash
. /opt/fsl-imx-xwayland/4.14-sumo/environment-setup-aarch64-poky-linux
```
before I run qmake & make:
```
qmake app.pro
make
```
These two commands should create the ELF file ready to run under the ARM.



## install and run the application
```bash
QT_QPA_PLATFORM_PLUGIN_PATH=/ptath/to/plugins ./app 
```
In Gentoo desktop, the plugin path is */usr/lib/qt5/plugins/platforms/*, so when we install the qt5 libraries that application depends on, we should install it in the correct location. To install the application as part of an image, we have to write an appropriate bitbabke file that will install all dependencies. See [recipes-qt](https://github.com/meta-qt5/meta-qt5/tree/40054db1de152d85c22aefdae50b136ca56967c5/recipes-qt)  to understand which files it requires to install. 

{{< figure src="/post/qt5_hello_world_for_embedded_device/demo_app.jpeg" title="Demo Application" >}}


## References
[1] https://stackoverflow.com/questions/17106315/failed-to-load-platform-plugin-xcb-while-launching-qt5-app-on-linux-without  
[2] https://stackoverflow.com/questions/50119427/how-can-i-capture-terminal-output-from-a-bash-script-and-display-it-in-my-qt-ui  
[3] https://forum.qt.io/topic/78532/qprocess-execute-capture-output
