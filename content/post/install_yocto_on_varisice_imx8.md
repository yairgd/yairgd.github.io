---
title: "Install Yocto and kernel development tools of IMX8"
description: "Install Yocto and kernel development tools of IMX8 "
tags : 
- "kernel"
- "yocto"

date : "2020-02-24"
archives : "2020"
categories : 
- "linux"

menu : "no-main"
---

# The GCC toolchain and kernel installation.
The purpose of this post is to show the installation process of development tools for imx8m-var-dart, which is SOM made by [Variscite](http://variwiki.com/index.php?title=Main_Page). Usually, a kernel, userspace applications, and toolchain built as part of a Yocto image but, for continuous development purposes, when custom kernel modules or userspace applications  developed, it is more comfortable with making it stand-alone and working on it outside the Yocto image.

## Toolchain
```bash
cd ~/var-fsl-yocto
MACHINE=imx8m-var-dart DISTRO=fsl-imx-xwayland . var-setup-release.sh -b build_xwayland
bitbake meta-toolchain
```

and then install it:
```bash
cd rootfs
$ find . -type f -exec scp {} root@a.b.c.d:/  \;
```
where *a.b.c.d* is the ip of the target

## Kernel
To build the kernel, do the following steps:
* Download the kernel
```bash
git clone https://github.com/varigit/linux-imx.git
cd linux-imx
git checkout imx_4.14.78_1.0.0_ga_var01
```


edit this file:
```bash
vim arch/arm64/boot/dts/freescale/Makefile
```
and add to its end the following line:
```bash
dtb-y                         += fsl-imx8mq-var-dart-your-dtb.dtb
```

* compile build
```bash
source /opt/fsl-imx-xwayland/4.14-sumo/environment-setup-aarch64-poky-linux
export LDFLAGS=
```
```bash
make mrproper 
make imx8_var_defconfig ARCH=arm64
```
```bash
# Customize the kernel configuration (optional step):
make menuconfig ARCH=arm64
```
```bash
make ARCH=arm64 CROSS_COMPILE=/opt/fsl-imx-xwayland/4.14-sumo/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-
make modules ARCH=arm64 CROSS_COMPILE=/opt/fsl-imx-xwayland/4.14-sumo/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-
make dtbs ARCH=arm64 CROSS_COMPILE=/opt/fsl-imx-xwayland/4.14-sumo/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-
```

* installation - change directory to **linux-imx-src** and run the following code:
```bash
# Install the kernel image and modules:
mkdir rootfs/boot -p
kver=$(strings arch/arm64/boot/Image | grep -i "Linux version" | awk '{print $3}')
sudo cp arch/arm64/boot/Image.gz rootfs/boot/Image.gz-${kver}
sudo make ARCH=arm64 modules_install INSTALL_MOD_PATH=rootfs
cd rootfs/boot
sudo ln -fs Image.gz-${kver} Image.gz
cd ..  # up to roofs

# Install the device trees:
find . -type f -exec scp {} root@a.b.c.d:/  \;
scp arch/arm64/boot/dts/freescale/fsl-imx8mq-var-dart-your-dtb.dtb root@a.b.c.d:/boot
```
where *a.b.c.d.* is the ip of the target device
# compiling userspace application with external library
when a userspace application makes use with an external library, this library can add as a dependency to the [bitbake](https://www.yoctoproject.org/docs/1.6/bitbake-user-manual/bitbake-user-manual.html) file, which creates the application. The yocto process will take the library, will build and link it with the application.  If we want to compile the application in userspace as part of a continuous development process, we can build it using *bitbake* command and place it under the root system of the compiler.

