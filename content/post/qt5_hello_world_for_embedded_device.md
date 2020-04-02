---
title: "Simple Hello World application using qt5 for embbeded linux device"
description: "Simple Hello World application using qt5 for embbeded linux device"
draft: true
tags : 
 - "linux"
 - "qt5"
 - "embedded"

date : "2020-04-1"
archives : "2020"
categories : 
 - "linux"
 - "qt5"

menu : "no-main"
---
This is a simple  example how to a create a qt5 application for linux embbeded device that runs wayland or x-server. I'm using yocto build system. I already have a bsp for IMX8 + toolchain so , I just have to install qt5 on it. In the time that I wrote this page I worked with *sumo* branch and had to make some work around  over 3 bugs that I found during the comilation of qt5. See [here](https://github.com/varigit/variscite-bsp-platform) a refferece to yocto project.

## bug workaroud
* applay this [patch](https://codereview.qt-project.org/c/qt/qtbase/+/245425/3/src/corelib/global/qrandom.cpp#b219)
* tmp/work/x86_64-linux/qtbase-native/5.10.1+gitAUTOINC+6c6ace9d23-r0/git/src/corelib/io/qfilesystemengine_unix.cpp
* line 101,107 - remove static keywork - sice it was feined as extern in another file
* remove line 106 since is couse to mulity definition


## install qt5-layer 
The layer [meta-qt5](https://github.com/meta-qt5) shoud deined on *local/conf/bblayers.conf* and the folloing command shoud run under the build directory:

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
I created a very simple application using qt-creator and I had to run this command:
```bash
. /opt/fsl-imx-xwayland/4.14-sumo/environment-setup-aarch64-poky-linux
```
before I run qmake:
```
qmake app.pro
make
```
after the an ELF file for arm shoud have to create.



## install and run athe application
```bash
QT_QPA_PLATFORM_PLUGIN_PATH=/ptath/to/plugins ./app 
```
where in gentoo desktop the plug in path is: */usr/lib/qt5/plugins/platforms/* , so when we install the qt5 libraries that application  depends on, we should install it in the correct location. To install the application as part of image , we have to write an apreporiate bitbabke file that will install the whole dependecies. See [recipes-qt](https://github.com/meta-qt5/meta-qt5/tree/40054db1de152d85c22aefdae50b136ca56967c5/recipes-qt)  to uderstand which files are requires to be intsalled.

{{< figure src="/post/qt5_hello_world_for_embedded_device/demo_app.jpeg" title="Demo Application" >}}


## References
[[1]] https://stackoverflow.com/questions/17106315/failed-to-load-platform-plugin-xcb-while-launching-qt5-app-on-linux-without  
