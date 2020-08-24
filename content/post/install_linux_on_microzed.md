---
title: "install linux on microzed board "
description: " linux image for microzed development board with yocto "
draft: false
tags : 
 - "zynq"
 - "yocto"
date : "2020-08-01"
archives : "2020"
categories : 
 - "linux"

menu : "no-main"
---
The [microzed](http://zedboard.org/product/microzed) developmnet board has zilinx zynq7000 chip. It has application proccess unit with cortex a9  and FPGA fabric. The board also contains interfaces like SDIO and QSPI. I want to install linux on it directly with yocto and without petalinux, which  runs yocto behind the scene so I tried to eliminate the need of using it.  why to so ? 
* It is intersting and I have alot of experiance with yocto an it very easy to work with its script once you know it 
* work the same as other proccessos: IMX , stm32Mp157 etc'
* using build tools like cmake,autotools and yocto script make it very easy to port SW between different proccessors.

I found the [meta-xilinx](https://github.com/Xilinx/meta-xilinx) layer and used it to build a linux system for the microzed board. Reffer [here](https://github.com/Xilinx/meta-xilinx/tree/master/meta-xilinx-bsp/conf/machine)  for a list  supported boards and creating a custom board can be very easy if one tracks the exsisting ones.


## yocto instlation
The basic yocto installation inludes poky and meta-xilinx layers; Just  check out the following yocto layers and switch to zeus barach:
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
 USe the follwoing yocto builds:
```bash
# to crate minimal cpio image (3M Bytes) + kernel + u-boot
bitbake core-image-minimal
bitbake u-boot
```

### flash image on qspi

#### FSBL
generate FSBL for microzed platform board. The board definition files (BDF) sould be instaled on vivado as reffer [here](https://github.com/Avent/bdf).

#### boot.bin
To create boot we can use bootgen which is tool of xilinf or to use [mkbootimage](https://github.com/antmicro/zynq-mkbootimage) which is open source replacement for xilinx bootgen tool. The parameters of the boot image file: load and offset address were taken from u-boot file [zynq-common.h](https://gitlab.denx.de/u-boot/u-boot/-/blob/master/include/configs/zynq-common.h) .

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
To flash the image on the qspi is has to set the board at jtag init mode  and run the following command:
```bash
program_flash -f /path/to/boot.bin -offset 0 -flash_type qspi_single -fsbl /path/to/fsbl_microzed.elf -blank_check -verify -cable type xilinx_tcf url TCP:127.0.0.1:3121
```

#### manual boot
This u-boot commands will read files from qspi and will loade the inux kernel. it can als automate using u-boot enviroment variables and scripts.
```bash
sf read 0x2000000 0x620000 0x500000
sf read 0x3000000 0x100000 0x5e0000
sf read 0x2a00000 0x600000 0x20000
bootm  0x3000000  0x2000000 0x2a00000
```

### boot image on sdcard

The stages for flashing image on sdcard are similiar to those that has on the qspi. But I was to use comleptle open source without FSBL. The idea is to take the *boot.bin* file that is generated using vivado tools and replace it with the secondary boot loader (SPL). The most important file is [ps7_init_gpl.c](https://gitlab.denx.de/u-boot/u-boot/-/blob/master/board/xilinx/zynq/zynq-microzed/ps7_init_gpl.c) and it  was generrated using Vivado , it is platform unique and reposible to initilize the most critical peripherials in the board: The DDR contoller, clocks and mio pins. If a new platform is design then, is has to genertae a new file for the new platorm.  The following bash script creates a binary boot image file and its name should be *boot.bin*. The following files were copy to the sdcard , reffer [here](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841976/Prepare+boot+image) for more details:

{{< table >}}
| file | name on sdcard | note                         |
|--------------|----------------|-------------------------------
| boot.bin     | BOOT.bin       | replace the previous boot.bin| 
| yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.2+gitAUTOINC+b983d5fd71-r0/deploy-linux-xnx/uImage|  uImage| u-boot image of linux kernel|
| yocto/build/tmp/deploy/images/microzed-zynq7/core-image-minimal-microzed-zynq7.cpio.gz.u-boot |  uramdisk.image.gz |u-boot image of compressed pio file system|
| yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/u-boot/1_2019.07-r0/build/u-boot.img |  u-boot.img| This is a u-boot image that contains u-boot.bin. It is loaded by SPL. [Reffer](https://github.com/Xilinx/u-boot-xlnx/blob/master/include/configs/zynq-common.h) here to the default name *u-boot.img* that is used by SPL|
{{<table>}}

The names above arrivbed from the *boot.cmd* which is genrated during the yocto build.
```bash
$ yocto/build/tmp/work/microzed_zynq7-poky-linux-gnueabi/u-boot-zynq-scr/1.0-r0 $ cat boot.cmd
fatload mmc 0 0x2000000 zynq-microzed.dtb
fatload mmc 0 0x2080000 uImage
fatload mmc 0 0x4000000 uramdisk.image.gz
bootm 0x2080000 0x4000000 0x2000000
```

### TO do: Intall boot image on qspi with SPL
To eliminate the FSBL when using QSPI.



## References
[1] [Creating a Bootable Image and Program the Flash](https://www.xilinx.com/html_docs/xilinx2018_1/SDK_Doc/xsct/use_cases/xsct_create_bootable_image.html)
