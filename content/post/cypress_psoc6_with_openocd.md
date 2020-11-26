---
draft: false
title: "Debugging of cypress psoc6 in Linux terminal."
description: "an example of how to use OpenOCD with dual-core cypress psoc6."
tags : 
 - "cypress."
 - "openocd"

date : "2020-11-05"
archives : "2020"
categories : 
 - "embedded"

menu : "no-main"
---
I have used OpenOCD in my embedded projects, and here is a simple explanation how to work with OpenOCD with  [PSOC6](https://www.cypress.com/documentation/development-kitsboards/psoc-6-ble-pioneer-kit-cy8ckit-062-ble) of cypress and here.   Cypress has its own porting for [OpenOCD](https://github.com/Cypress-OpenOCD/OpenOCD) for its [interfaces](https://www.cypress.com/documentation/development-kitsboards/kitprog-user-guide): kitprog3 & kitprog4. Usually, I work on a Linux terminal using a command line with cgdb but, OpenOCD is already installed on [modus](https://www.cypress.com/products/modustoolbox-software-environment), the default IDE of cypress.  
The PSOC6 is dual-core MCU: CM0+ and CM4, and when booting, it first powers on the CM0+, and if the CM4 is also needed,  the CM0+ has to power it on.  Using OpenOCD, it can debug both processors at the same time. Each processor will have a separate port that will control it.


## OpenOCD setup
This is my favorite setup when working with an embedded project on a Linux terminal. 

Run the OpenOCD server. The cypress programmer should be connected. 

```bash
cd  ~/path/to/cypress/openocd/scripts  
sudo ../bin/openocd -f interface/kitprog3.cfg -f target/psoc6.cfg -c "program /home/yair/bis25/Debug/frontend/cm4_src/cm4"
```

I added the following addition to the original *psoc6.cfg* so port 60000 contrlos CM4 and port 70000 to controls CM0+ and also added thread awereness when using freeertos on CM4.
```bash
psoc6.cpu.cm4 configure -gdb-port 60000
psoc6.cpu.cm0 configure -gdb-port 70000
psoc6.cpu.cm4 configure -rtos auto -rtos-wipe-on-reset-halt 1
```

In another terminal, I open a telnet session to the OpenOCD server using the default 4444 port
```bash
telnet  127.0.0.1 4444
```

In the telnet session, I have used this command to program the device (Usually after compilation)
```bash
program /path/to/cm4/prog.elf;reset
```

 and this is the output message :
```bash
kitprog3: acquiring PSoC device...
target halted due to debug-request, current mode: Thread 
xPSR: 0x01000000 pc: 0x00001f34 msp: 0x080477a8
** Device acquired successfully
** psoc6.cpu.cm4: Ran after reset and before halt...
target halted due to debug-request, current mode: Thread 
xPSR: 0x61000000 pc: 0x1600400c msp: 00000000
** Programming Started **
auto erase enabled
Flash write discontinued at 0x10009530, next section at 0x10080000
Padding image section 0 at 0x10009530 with 208 bytes (bank write end alignment)
[100%] [################################] [ Erasing     ]
[100%] [################################] [ Programming ]
Padding image section 2 at 0x10093d5c with 164 bytes (bank write end alignment)
[100%] [################################] [ Erasing     ]
[100%] [################################] [ Programming ]
wrote 119808 bytes from file /path/to/cm4/prog.elf  in 3.906287s (29.952 KiB/s)
```

## gdb setup
It has to place the following content in the file *~/.gdbinit*. This creates a custom *reset* command that restarts the debugging session. You can name it "r" to make consume time during debugging.

```gdb
define reset
  mon reset    				# reset the whole chip
  mon psoc6 reset_halt sysresetreq      # resets and halts only cm4 (or cm0+)
  flushregs 	                        # taken from modus
  mon gdb_sync                          # taken from modus
  stepi
  c         
end
```

before any call to *restart* it has to connect to the OpenOCD server using:
```gdb
target remote 127.0.0.1 PORT
```

Where *PORT* is either 60000 to debug CM4 or nighter 70000  to debug CM0+, needless to say that, the target elf file should be for the correct processor.



## References
[[1] https://www.mouser.com/pdfdocs/AN221774_Getting_Started_with_PSoC_6_MCU.pdf](https://www.mouser.com/pdfdocs/AN221774_Getting_Started_with_PSoC_6_MCU.pdf)

