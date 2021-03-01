---
title : "Linux module magic info "
description : "Linux module magic info"
tags : 
 - "linux"
 - "kernel"
 - "rt"

date : "2020-02-20"
archives : "2020"
categories : 
 - "linux"
 - "embedded"
author : "Yair Gadelov"

menu : "no-main"
---
Sometimes we want to build a module separate from the kernel.  When the kernel is built, it generates a magic number, which probably depends on compiler version, kernel version, git source revision, etc. Time is also probably part of this magic number, since the kernel may build with the same parameters but with a different timestamp, it will have a different magic number, and then we will get this message when we try to insert it:
```bash
root@linux:~# insmod /lib/modules/4.14.78-imx8m+g7808f06d8af2/extra/hello.ko
insmod: ERROR: could not insert module /lib/modules/4.14.78-imx8m+g7808f06d8af2/extra/hello.ko: Invalid module format
```

## recompile module

just got to this file and change UTS_RELEASE:
```bash
$ cat ./include/generated/utsrelease.h
#define UTS_RELEASE "4.14.78-g8e54a4b719e6"
``` 

## module that we cannot recompile 
To handle this situation without installing a new kernel + modules, we will replace the module magic number. This not work for some reason that I don't understand.  The easy and the right way is to change the *utsrelease.h* file explained above. I'm sure that what I'm doing here is correct, but since I already start to investigate it, I will keep it here for sometime else.  

The kernel  version can be achieved form this command:
```bash
$strings arch/arm64/boot/Image | grep -i "Linux version" 
Linux version 4.14.78-g8e54a4b719e6 (yair@yair) (gcc version 7.3.0 (GCC)) #1 SMP PREEMPT Tue Oct 22 11:54:22 IDT 2019
```
and the module version is archive from :
```bash
modinfo -F vermagic hello.ko
```
The full modinfo section can be displayed by:
```bash
$ objdump -s -j .modinfo hello.ko

hello.ko:     file format elf64-little

Contents of section .modinfo:
 0000 6c696365 6e73653d 47504c00 00000000  license=GPL.....
 0010 64657065 6e64733d 006e616d 653d6865  depends=.name=he
 0020 6c6c6f00 7665726d 61676963 3d342e31  llo.vermagic=4.1
 0030 342e3738 2d673865 35346134 62373139  4.78-g8e54a4b719
 0040 65362053 4d502070 7265656d 7074206d  e6 SMP preempt m
 0050 6f645f75 6e6c6f61 64206161 72636836  od_unload aarch6
 0060 3400
```

To get the module magic number run:
```bash
$ modinfo hello.ko
filename:       hello.ko
license:        GPL
depends:        
name:           hello
vermagic:       4.14.78-g8e54a4b719e6 SMP preempt mod_unload aarch64
```

copy the modinfo section to a file:
```bash
export OBJCOPY=/opt/fsl-imx-xwayland/4.14-sumo/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-objcopy
$OBJCOPY  ./hello.ko  /dev/null --dump-section .modinfo=mod_info
```

update the magic number
```bash
sed  's/4.14.78-g8e54a4b719e6/4.14.78+g7808f06d8af2/g' -i mod_info
```
update the module
```bash
$ $OBJCOPY --remove-section=.modinfo --add-section .modinfo=mod_info  hello.ko
```
test for the new magic number
```bash
$  modinfo hello.ko
filename:       hello.ko
license:        GPL
depends:        
name:           hello
vermagic:       4.14.78+g7808f06d8af2 SMP preempt mod_unload aarch64
```

### Related issues
example of two related issues:

* See [here](https://archives.gentoo.org/gentoo-user/message/3d188075a832cf3ab3926abcf6c7413b) for a bug report which relates to this issue. The problem there was that the file *./include/generated/utsrelease.h* did not exist. To fix, it only has to recompile the kernel.

* Fail during the compilation of *sys-kernel/spl-0.7.13* at Gentoo system. Again, in this case, just need to build the kernel and make */usr/src/linux* points to it.

```bash
checking spl config... all
checking kernel source directory... /usr/src/linux
checking kernel build directory... /usr/src/linux
checking kernel source version... Not found
configure: error: *** Cannot find UTS_RELEASE definition.

!!! Please attach the following file when seeking support:
!!! /var/tmp/portage/sys-kernel/spl-0.7.13/work/spl-0.7.13/config.log
 * ERROR: sys-kernel/spl-0.7.13::gentoo failed (configure phase):
 *   econf failed
 * 
 * Call stack:
 *               ebuild.sh, line  125:  Called src_configure
 *             environment, line 4738:  Called autotools-utils_src_configure
 *             environment, line  934:  Called econf '--docdir=/usr/share/doc/spl-0.7.13' '--bindir=/bin' '--sbindir=/sbin' '--with-config=all' '--with-linux=/usr/src/linux' '--with-linux-obj=/usr/src/linux' '--disable-debug'
 *        phase-helpers.sh, line  681:  Called __helpers_die 'econf failed'
 *   isolated-functions.sh, line  112:  Called die
 * The specific snippet of code:
 *           die "$@"
 * 
 * If you need support, post the output of `emerge --info '=sys-kernel/spl-0.7.13::gentoo'`,
 * the complete build log and the output of `emerge -pqv '=sys-kernel/spl-0.7.13::gentoo'`.
 * The complete build log is located at '/var/tmp/portage/sys-kernel/spl-0.7.13/temp/build.log'.
 * The ebuild environment file is located at '/var/tmp/portage/sys-kernel/spl-0.7.13/temp/environment'.
 * Working directory: '/var/tmp/portage/sys-kernel/spl-0.7.13/work/spl-0.7.13'
 * S: '/var/tmp/portage/sys-kernel/spl-0.7.13/work/spl-0.7.13'
```


## reference
[[1] How to change the vermagic of a module](https://www.linuxquestions.org/questions/linux-kernel-70/how-to-change-the-vermagic-of-a-module-728387/)

