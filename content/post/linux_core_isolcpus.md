---
title: "Linux core isolation"
description: "Linux core isolation to have a close RT performance "
tags : 
- "linux"
- "kernel"
- "rt"

date : "2020-02-18"
archives : "2020"
categories : 
- "linux"
- "embedded"
author : "Yair Gadelov"

menu : "no-main"
---
I have a real-time task that needed to run periodically at a constant rate - a continuous IRQ drives it.  Just running this task on a multithreaded environment can cause it to run in different timing values. When the system runs on stress (using stress [utility](https://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/)) the system is not a response to all IRQ requests.  A possible solution to this problem is to use Linux core isolation. In this case, we assign a specific core for the task, and the Linux kernel is getting out from the SMP balancing, and this core can use for a particular job with minimal interrupts.


turn on the device and press any key to stop u-boot and command line. Type the following command (which can change between different board)
```bash
setenv mmcargs "setenv bootargs console=${console} root=${mmcroot} video=${video} isolcpus=2"
```
after boot,  type and see the isolated core.
```bash
# cat /sys/devices/system/cpu/isolated
2
```

## References
Here are some reference sources that used to create this post  
[[1] Whole one core dedicated to a single process](https://stackoverflow.com/questions/13583146/whole-one-core-dedicated-to-single-process)  
[[2]  INTERRUPTS AND IRQ TUNING](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/performance_tuning_guide/s-cpu-irq)  
[[3] how to detect if isolcpus is activated?](https://unix.stackexchange.com/questions/336017/how-to-detect-if-isolcpus-is-activated)
