---
title : "Linux core isoation to have a close RT performance"
description : "Linux core isolation to have a close RT performance "
tags : 
 -"linux"
 -"kernel"
 -"rt"

date : "2020-02-18"
archives : "2020"
categories : 
 -"linux"
 -"embbeded"
draft: true

menu : "no-main"
---
# Linux core isolation
I have a real-time task that needed to run periodically at a constant rate at a constant time each time. Just running this task on a multithreaded environment can cause it to run in different timing values. A possible solution to this problem is to use Linux core isolation. In this case, the Linux kernel is got out from the SMP balancing and the CPU can be used for a specific task with minimal interrupts.  







# References
Here are some reference sources that used to create this post  
[[1] Whole one core dedicated to a single process](https://stackoverflow.com/questions/13583146/whole-one-core-dedicated-to-single-process) 
