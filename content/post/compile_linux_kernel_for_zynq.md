---
title: "Compile Linux kernel for zynq "
description: "How to build the Linux kernel for zynq in separate and not as part of the yocto build."
tags : 
 - "linux"
 - "kernel"
 - "yocto"

date : "2020-10-17"
archives : "2020"
categories : 
 - "linux"

menu : "no-main"
---
 In previous [post]({{< ref "/post/install_linux_on_microzed.md" >}} ) I shoed how to build and install Linux system on microzed board. When one tries to modify the kernel & u-boot, it is better to build and test it separately outside the Yocto build.  I use Yocto's kernel & u-boot sources and its SDK for the custom build.


## build the kernel

To enable SDK , just type the following command. 
```bash
. /opt/poky/3.0.3/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi
```
This script will define a series of enviement variables like $CC & $CXX that needed for the build. For exmaple $CC contains the following value:
```bash
arm-poky-linux-gnueabi-gcc -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a9 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/opt/poky/3.0.3/sysroots/cortexa9t2hf-neon-poky-linux-gnueabi
```
copy the kernel sources from  */path/to/yocto-install/build/tmp/work-shared/microzed-zynq7/kernel-source* to clean the working directory and run this commands to build the kernel

```bash
cd /path/to/kernel-source
make ARCH=arm  make xilinx_zynq_defconfig
make
```
To create a u-boot image (uImage file),  which is a container that holds a binary file of Linux kernel, and its target memory is at address  0x8000,  just run the following command:
```bash
make -j5 UIMAGE_LOADADDR=0x8000 uImage
```
The kernel script *./scripts/Makefile.lib*  translates this command  to:
>```bash
>quiet_cmd_uimage = UIMAGE  $(UIMAGE_OUT)
>      cmd_uimage = $(CONFIG_SHELL) $(MKIMAGE) -A $(UIMAGE_ARCH) -O linux \
>			-C $(UIMAGE_COMPRESSION) $(UIMAGE_OPTS-y) \
>			-T $(UIMAGE_TYPE) \
>			-a $(UIMAGE_LOADADDR) -e $(UIMAGE_ENTRYADDR) \
>			-n $(UIMAGE_NAME) -d $(UIMAGE_IN) $(UIMAGE_OUT)
>```
This command uses *mkimgae* utiliety which belongs to u-boot utils and can be found under yocto build artifacts or just install u-boot-utils to linux using (gentoo):
```bash
emerge u-boot-utils
```


In [minized](http://zedboard.org/product/minized), for example, there is only QSPI, so changing the file system created by Yocto and adding new modules may require some scripting work, but when using an sd card, it is easy also to build the modules and install it on the root file system.  
```bash
mkdir rootfs/boot -p
kver=$(strings arch/arm64/boot/Image | grep -i "Linux version" | awk '{print $3}')
sudo cp arch/arm/boot/Image.gz rootfs/boot/Image.gz-${kver}
sudo make ARCH=arm modules_install INSTALL_MOD_PATH=/path/to/target/root/file/system
```
After any change in the DTS file, recompile it without recompile the whole kernel. 
```bash
make dtbs ARCH=arm
```
And again, If the board has an sd card, it easy to copy the  DTS file to the target file system. If it uses QSPI, it has to prepare [image](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_2/ug1283-bootgen-user-guide.pdf)  for QSPI.  

## build the u-boot
To do





## References
[[1] https://wiki.analog.com/resources/eval/user-guides/ad-fmcomms2-ebz/software/linux/zynq_2014r2](https://wiki.analog.com/resources/eval/user-guides/ad-fmcomms2-ebz/software/linux/zynq_2014r2)  


