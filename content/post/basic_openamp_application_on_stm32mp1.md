---
title: "Simple OpenAMP application for stm32mp157 "
description: "How to build the Linux kernel for zynq in separate and not as part of the yocto build."
tags : 
 - "linux"
 - "kernel"
 - "yocto"
 - "stm32"

date : "2020-10-25"
archives : "2020"
categories : 
 - "embedded"
 - "linux"

menu : "no-main"
---

The [stm32mp157](https://www.st.com/en/microcontrollers-microprocessors/stm32mp157.html) is SOC from STMicrocntrollers, and it has within it a dual-core-a7 MPU and cortex-m4 MCU. The Core-a7 is an application processor that operates Linux, and the Cortex-m4 runs RTOS or bare-metal application. The Cortex-m4 can be used for real-time tasks, such as creating a very acquire and high-speed signal waveform for real-time operates purposes. In this kind of application, the cortex-a7 will run the master application will control the application on the Cortex-m4 using [RPMsg Messaging Protocol](https://github.com/OpenAMP/open-amp/wiki/RPMsg-Messaging-Protocol). I have used [STM32MP157C-DK2](https://www.st.com/en/evaluation-tools/stm32mp157c-dk2.html#)  evaluation kit to create a simple hello world messaging application between the cortex-a7 (Linux) to cortex-m4 (bare metal) 



## install necessary tools
The working environment is Linux and usually and I had to install [repo](https://gerrit.googlesource.com/git-repo/) tool (Gentoo)
```bash
emerge dev-vcs/repo
```

I had followed the instruction in this manual [ref](https://wiki.st.com/stm32mpu/index.php/STM32MP1_Distribution_Package).
```bash
mkdir yocto
cd yocto
repo init -u https://github.com/STMicroelectronics/oe-manifest.git -b refs/tags/openstlinux-5.4-dunfell-mp1-20-06-24
repo sync
```
Build yocto image and toolchain:
```bash
DISTRO=openstlinux-weston MACHINE=stm32mp1 source layers/meta-st/scripts/envsetup.sh
bitbake core-image-base
bitbake meta-toolchain
bitbake st-image-weston
```
To install the tool can make sure that you are in the build directory (*build-openstlinuxweston-stm32mp1* - by default) and type:
```bash
. meta-toolchain-openstlinux-weston-stm32mp1-x86_64-toolchain-3.1-snapshot.sh
```

ST recommends installing [STM32CubeIDE](https://www.st.com/en/development-tools/stm32cubeide.html), which is basically an eclipse environment with pre-installed GCC and other useful tools like [openocd](http://openocd.org/).  I usually work without IDE, and GCC was downloaded from [here](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads/7-2018-q2-update)


## kernel & u-boot & sd image
I have used the default image that gets with the development kit, so everything was there and defined correctly. I will write a post on creating an adapted image for the stm32mp1 that includes: kernel, u-boot, and file system. I also used a default application given by   [STM32Cube_FW_MP1_V1.2.0 ](https://wiki.st.com/stm32mpu/index.php/Getting_started/STM32MP1_boards/STM32MP157x-EV1/Develop_on_Arm%C2%AE_Cortex%C2%AE-M4/Install_STM32Cube_MP1_package).


## debug Cortex-M4
The board has two modes: engineering mode where it can work on the Cortex-M4 using JTAG as it has done in any other ST microcontroller. The Cortex-M4 core will be automatically started in engineering mode once you power the board, and the Cortex-A core will not run the regular SD card boot process. This allows quickly prototyping Cortex-M4 firmware without configuring the Linux-level settings. In the production mode, the device boots from Cortex-A7, and the Cortex-M4 is disabled and only can be accessed from the Linux OS. To load and activate the Cortex-M4 firmware in production mode it has to type.

```bash
echo stop > /sys/class/remoteproc/remoteproc0/state                    # power up Cortex-M4
echo test2_CM4.elf  > /sys/class/remoteproc/remoteproc0/firmware       # loads firmware to Cortex-M4 - it can also be done using openocd after power up of Cortex-M4
echo start > /sys/class/remoteproc/remoteproc0/state                   # power down Cortex-M4
```
Refer [here](https://wiki.st.com/stm32mpu/wiki/Linux_remoteproc_framework_overview) for more details on the remote processor framework. 


if both modes the debuggeing procedure is the same using openocd:
```bash
$ . /opt/st/stm32mp1/3.1-snapshot/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi 
$ $OECORE_NATIVE_SYSROOT/usr/bin/openocd -s $OECORE_NATIVE_SYSROOT/usr/share/scripts -f board/stm32mp15x_dk2.cfg
```

In gdb session typw the following  commands:
```bash
arm-none-eabi-gdb test2_CM4.elf
```

In the gdb prompt command type:
```bash
target remote 127.0.0.1:3334 # look at the output of the above openocd to determine the correct port to control Cortex-M4
monitor soft_reset_halt
step
c
 ```
ST provides [IDE](https://www.st.com/en/development-tools/stm32cubeide.html), which based on eclipse and has all the needed facilities to support debugging with IDE.  Usually, I'm using [cgdb](https://cgdb.github.io/), and the following figure displays a Cortex-M4 debug session using cgdb (in the left window) and Linux kernel lot output (right window) with hello messages they were sent from the Cortext-M4 using OpenMP.

{{< figure src="/post/hello_message_comming_from_cortex_m4.png" title="Linux kernel log: Hello message commining from Cortex-M4 to Cortex-A9 " >}}


## To do
to display m4 logs from linux user space [here](https://emcraft.com/som/stm32mp1/loading-firmware-to-the-m4-core-and-using-rpmsg-for-inter-core-communications)

## References
[[1] https://visualgdb.com/tutorials/arm/stm32/stm32mp1/](https://visualgdb.com/tutorials/arm/stm32/stm32mp1/)  
[[2] https://community.st.com/s/question/0D50X0000B6QncT/debugging-m4-with-gdb-from-command-line](https://community.st.com/s/question/0D50X0000B6QncT/debugging-m4-with-gdb-from-command-line)  
[[3] https://events19.linuxfoundation.org/wp-content/uploads/2017/12/Linux-and-Zephyr-%E2%80%9CTalking%E2%80%9D-to-Each-Other-in-the-Same-SoC-Diego-Sueiro-Sepura-Embarcados.pdf](https://events19.linuxfoundation.org/wp-content/uploads/2017/12/Linux-and-Zephyr-%E2%80%9CTalking%E2%80%9D-to-Each-Other-in-the-Same-SoC-Diego-Sueiro-Sepura-Embarcados.pdf)  




