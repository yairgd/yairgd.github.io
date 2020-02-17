---
title : "Linux core isoation to have a close RT performance"
description : "Linux core isolation to have a close RT performance "
tags : 
 - "linux"
 - "kernel"
 - "rt"

date : "2020-02-18"
archives : "2020"
categories : 
 - "linux"
 - "embbeded"
draft: true

menu : "no-main"
---
# Linux core isolation
I have real time task that needed to run perodiclly in constat rate at constatnt time each time. Just running this task on multythread envieronemt can cause it to run in various timing value. Possible solution to this robblem is to use linux core isolation. In this case the linux kenele is got  out from the SMP blancing and the CPU can used for a specifi task with minimal  interrupts. 







# References
Here are some reference sources that used to create this post  
[[1] Whole one core dedicated to single process](https://stackoverflow.com/questions/13583146/whole-one-core-dedicated-to-single-process)  

