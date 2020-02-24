---
title: "Linux core isolation to have a close RT performance."
description: "Linux core isolation to have a close RT performance "
tags : 
- "linux"
- "kernel"
- "rt"

date : "2020-02-18"
archives : "2020"
categories : 
- "linux"
- "embbeded"

menu : "no-main"
---
# Linux core isolation
I have a real-time task that needed to run periodically at a constant rate at a constant time each time. Just running this task on a multithreaded environment can cause it to run in different timing values. A possible solution to this problem is to use Linux core isolation. In this case, we assign a specific core for the task, and the Linux kernel is getting out from the SMP balancing and hat core cand use for a specific task with minimal interrupts.  



setenv mmcargs "setenv bootargs console=${console} root=${mmcroot} video=${video} isolcpus=2"

# References
Here are some reference sources that used to create this post  
[[1] Whole one core dedicated to a single process](https://stackoverflow.com/questions/13583146/whole-one-core-dedicated-to-single-process) 
