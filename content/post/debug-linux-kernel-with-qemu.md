---
title: "Debug Linux Kernel With Qemu"
description: "debug-linux-kernel-with-qemu"
author: "Yair Gadelov"
email: "yair.gadelov@gmail.com"
tags : 
- "linux"
- "kernel"
date : "2020-03-18"
archives : "2020"
categories : 
- "linux"
menu : "no-main"
---
I have tried to debug the Linux kernel using GDB and a system emulator [qemu](https://www.qemu.org/). I use YOCTO and standard [pokey](https://www.yoctoproject.org/software-item/poky/)  distribution to build Linux image and kernel. I made changes to the standard [.config](post/content/post/debug-linux-kernel-with-qemu/config) file to support debug symbols and remove the [KASLR option from the kernel](https://www.spinics.net/lists/newbies/msg59708.html)

## kernel config
The kernel has to modify as the following:
* Add debug symbols by adding this option author: CONFIG_DEBUG_INFO=y
* Remove KASLR definition from kernel by unset: CONFIG_RANDOMIZE_BASE. This is from kernel help:
>In support of Kernel Address Space Layout Randomization (KASLR),
>this randomizes the physical address at which the kernel image
>is decompressed and the virtual address where the kernel
>image is mapped, as a security feature that deters exploit
>attempts relying on knowledge of the location of kernel
>code internals

## run qemu
The qemu can run like that:
```bash
qemu-system-x86_64 -append 'console=/dev/ttyS0' \
		   -kernel /path/to/kernel-source/arch/x86_64/boot/bzImage \
		   -nographic \ 
		   -serial mon:stdio -S -s  -enable-kvm 
		   -drive file=/path/to/rootfs.ext4,if=virtio,format=raw
```
The roofts and the kernel made by Yocto. The -S tells the qemu to freeze after when it ready to run and -s pe gdbserver at 1234 by default. 


## setup the gdb
Afther compiling the kernel run this command in the kernel directory:
```bash
gdb ./vmlinux
```
or, it also possible to extract the debug symbols from *vmlinux* like that:
```bash
objcopy --only-keep-debug vmlinux kernel.sym
```
and in the gdb console type:
```bash 
file kernel.sym 
```
from GDB console use target remote and *monitor system_reset*  to controller the machine:
```bash
(gdb) target remote :1234
(gdb) hbreak start_kernel   # to stop at start_kernel function
(gdb) monitor system_reset  # if restart is needed
(gdb) monitor system_reset
(gdb) c
Continuing.

Breakpoint 3, start_kernel () at init/main.c:514
514	{
(gdb) l
509		/* Should be run after espfix64 is set up. */
510		pti_init();
511	}
512	
513	asmlinkage __visible void __init start_kernel(void)
514	{
515		char *command_line;
516		char *after_dashes;
517	
518		set_task_stack_end_magic(&init_task);
```


## References
https://yulistic.gitlab.io/2018/12/debugging-linux-kernel-with-gdb-and-qemu/  
https://unix.stackexchange.com/questions/396013/hardware-breakpoint-in-gdb-qemu-missing-start-kernel  
https://stackoverflow.com/questions/6710555/how-to-use-qemu-to-run-a-non-gui-os-on-the-terminal  

