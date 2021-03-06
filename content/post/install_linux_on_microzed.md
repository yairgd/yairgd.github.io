---
title : "install linux on microzed board "
description: " linux image for microzed development board with yocto "
draft: false
tags : 
 - "zynq"
 - "yocto"
date : "2020-08-01"
archives : "2020"
categories : 
 - "linux"
author : "Yair Gadelov"

menu : "no-main"
---
The [microzed](http://zedboard.org/product/microzed) development board has Xilinx zynq7000 chip. It has an application process unit with cortex a9  and FPGA fabric. The board also contains interfaces like SDIO and QSPI. I want to install Linux on it directly with yocto and without petalinux, which runs yocto behind the scene, so I tried to eliminate the need to use it. Why do so? 
* It is interesting, and I have a lot of experience with yocto and it very easy to work with its script once you know it 
* easy porting to other processors: IMX, stm32Mp157, etc'
* using build tools like CMake,Autotools, and yocto scripts make it very easy to port SW between different processors.

I found that [meta-xilinx](https://github.com/Xilinx/meta-xilinx) layer and used it to build a Linux system for the microzed board. Refer [here](https://github.com/Xilinx/meta-xilinx/tree/master/meta-xilinx-bsp/conf/machine)  for a list supported bords and creating a custom board can be very easy if one tracks the existing ones.


## yocto installation
The basic yocto installation includes poky and meta-Xilinx layers; check out the following yocto layers and switch to zeus branch:
```bash
mkdir yocto
cd yocto
git clone git://git.yoctoproject.org/poky.git
git clone https://github.com/Xilinx/meta-xilinx
git clone http://github.com/Xilinx/meta-xilinx-tools
. ./poky/oe-init-build-env
```
add the meta-xilinx layers:
```bash
bitbake-layers add-layer /path/to/meta-xilinx
bitbake-layers add-layer /path/to/meta-xilinx-tools
```
and change the configration file conf/local.conf:
```bash
# to build microzed board
MACHINE ??= "microzed-zynq7"
# to allow c++ 
IMAGE_INSTALL_append = " libstdc++"
TOOLCHAIN_TARGET_TASK_append = " libstdc++-staticdev"
```
 Use the following yocto builds:
```bash
# to create minimal CPIO image (3M Bytes) + kernel + u-boot
bitbake core-image-minimal
bitbake u-boot
```

### flash image on QSPI

#### FSBL
The next step is to generate FSBL application for microzed platform board. The board definition files (BDF) should be installed on vivado as refer [here](https://github.com/Avnet/bdf). So, just create a new HW project in vivado for microzed and the export the XSA (of HDF) file to vitis (of SDK) and then create a new FSBL application.


#### boot.bin
To create the boot.bin file, we can use bootgen, which is a tool of Xilinx or to use [mkbootimage](https://github.com/antmicro/zynq-mkbootimage) which is an open-source replacement for Xilinx bootgen tool. I took the values of the parameters load and offset address from the u-boot file [zynq-common.h](https://gitlab.denx.de/u-boot/u-boot/-/blob/master/include/configs/zynq-common.h).

```bash
#!/bin/bash
UIMAGE_LOAD=0x3000000
DTB_LOAD=0x2a00000
FS_LOAD=0x2000000

KERNEL_ENTRY=0x100000
DTS_ENTRY=0x600000
RAM_FS_ENTRY=0x620000

cat << EOF > boot.bif
img : { 
	[bootloader]/home/yair/workspace2/fsbl_microzed/Release/fsbl_microzed.elf
	/home/yair/xilinx/yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/u-boot/1_2019.07-r0/build/u-boot.elf
	[load=${UIMAGE_LOAD},offset=${KERNEL_ENTRY}]yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.2+gitAUTOINC+b983d5fd71-r0/deploy-linux-xnx/uImage	
	[load=${DTB_LOAD},offset=${DTS_ENTRY}]yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.2+gitAUTOINC+b983d5fd71-r0/deploy-linux-xlnx/zynq-microzed-microzed-zynq7.dtb	
	[load=${FS_LOAD},offset=${RAM_FS_ENTRY}]yocto/build/tmp/deploy/images/microzed-zynq7/core-image-minimal-microzed-zynq7.cpio.gz.u-boot
}
EOF
bootgen  -image boot.bif -o i boot.bin -w 
```

#### flash the board
To flash the image on the qspi is has to set the board at jtag  mode  and run the following command:
```bash
program_flash -f /path/to/boot.bin -offset 0 -flash_type qspi_single -fsbl /path/to/fsbl_microzed.elf -blank_check -verify -cable type xilinx_tcf url TCP:127.0.0.1:3121
```
also so, it can [refer](https://www.xilinx.com/support/answers/70548.html) here about how to eliminate the need for JTAG mode by adding this line to FSBL at main.c
```c
/*
 * Read bootmode register
 */
BootModeRegister = Xil_In32(BOOT_MODE_REG);
BootModeRegister &= BOOT_MODES_MASK;

//add this line to trick boot mode to JTAG
BootModeRegister = JTAG_MODE; 
```

#### manual boot
This u-boot commands will read files from QSPI and will load the Linux kernel it can also automated using u-boot enviroment variables and scripts. 
```bash
sf probe 0 0 0 
sf read 0x2000000 0x620000 0x500000
sf read 0x3000000 0x100000 0x5e0000
sf read 0x2a00000 0x600000 0x20000
bootm  0x3000000  0x2000000 0x2a00000
```

### boot image on sd card

The stages for flashing images on the sd card are similar to those that have on the QSPI. But I was to use a completely open-source without FSBL. The idea is to take the *boot.bin* file ( generated using vivado tools) and replace it with the secondary boot loader (SPL). The most important file is [ps7_init_gpl.c](https://gitlab.denx.de/u-boot/u-boot/-/blob/master/board/xilinx/zynq/zynq-microzed/ps7_init_gpl.c) which one create it using vivado tools, and it also platforms unique and responsible to initialize the most critical peripherals in the board: The DDR controller, clocks and MIO pins. If a new platform is a design, then, is has to generate a new file for the new platform.  It has to copy the following files to the sd card, refer [here](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841976/Prepare+boot+image) for more details:

{{< table >}}
| file | name on sd card | note                         |
|--------------|----------------|-------------------------------
| boot.bin     | BOOT.bin       | It is the SPL and replace the previous boot.bin| 
| yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.2+gitAUTOINC+b983d5fd71-r0/deploy-linux-xlnx/microzed.dtb  | devicetree.dtb | The device tree file| 
| yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.2+gitAUTOINC+b983d5fd71-r0/deploy-linux-xnx/uImage|  uImage| u-boot image of linux kernel|
| yocto/build/tmp/deploy/images/microzed-zynq7/core-image-minimal-microzed-zynq7.cpio.gz.u-boot |  uramdisk.image.gz |u-boot image of compressed CPIO file system|
| yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/u-boot/1_2019.07-r0/build/u-boot.img |  u-boot.img| It is a u-boot image that contains u-boot.bin, and the SPL loads it from sd card extract the u-boot.bin and loads it to memory. [Reffer](https://github.com/Xilinx/u-boot-xlnx/blob/master/include/configs/zynq-common.h) here to the default name *u-boot.img* that is used by SPL|
{{</table>}}

The names mentioned in the table above, are arrived from the file  *boot.cmd* which process of yocto build generates that file.


```bash
$ yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/u-boot-zynq-scr/1.0-r0 $ cat boot.cmd
fatload mmc 0 0x2000000 zynq-microzed.dtb
fatload mmc 0 0x2080000 uImage
fatload mmc 0 0x4000000 uramdisk.image.gz
bootm 0x2080000 0x4000000 0x2000000
```

### TO do: Install boot image on QSPI with SPL
To eliminate the FSBL when using QSPI.



## References
[1] [Creating a Bootable Image and Program the Flash](https://www.xilinx.com/html_docs/xilinx2018_1/SDK_Doc/xsct/use_cases/xsct_create_bootable_image.html)
