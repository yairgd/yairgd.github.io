---
title: "Linux uio driver to handle with IRQ source "
description: "Linux uio driver to handle with external IRQ"
tags : 
 - "linux"
 - "kernel"
 - "rt"

date : "2020-02-24"
archives : "2020"
categories : 
 - "linux"
 - "embedded"

menu : "no-main"
---
 The Userspace I/O framework ([UIO](https://www.kernel.org/doc/html/v4.13/driver-api/uio-howto.html)) is part of the linux kernel and allows device drivers to be written almost entirely in userspace. UIO is suitable for hardware that does not fit into other kernel subsystems (Like special HW like FPGA)  and allowing the programmer to write most of the driver in userspace using all standard application programming tools and libraries. This greatly simplifies development, maintenance, and distribution of device drivers for this kind of hardware. I did  a simple project implemenetd on Xilinx Zynq that shows response to IRQ that come from perioic time that impelented on the FPGA part of the zynq. The PL side (ARM) responsed to the IRQ at user space ans allows versy quick periodic response to IRQ.


## FPGA design
This is a simple FPGA project made on Vivao. It has an ARM proccessor,GPIO and Fixed interval timert (FIT). The FIT is contolled by the ARM and enabled by internal GPIO bit. 
{{< figure src="/post/linux_uio_device_irq/uiofpga_block_design.png" title="The Block Desgin" >}}

The IRQ output of the FIT is is connected to the ARM interrupt at IRQ_F2P[0]
{{< figure src="/post/linux_uio_device_irq/irq_definition.png" title="IRQ Selection" >}}




## The driver code

here is the driver code:

```c
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/device.h>
#include <linux/uio_driver.h>
#include <linux/interrupt.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/of_platform.h> 

static struct uio_info *info;
static struct device *dev;
static int irq = 6;
module_param(irq, int, S_IRUGO);

static void my_release(struct device *dev)
{
	pr_info("releasing my uio device\n");
}

static irqreturn_t my_handler(int irq, struct uio_info *dev_info)
{
//	static int count = 0;
//	pr_info("In UIO handler, count=%d\n", ++count);
	return IRQ_HANDLED;
}

#define DEVNAME "fpga-belkin"
static int __init my_init(void)
{
	struct device_node * np = NULL;
	
	/* set IRQ */
	np = of_find_compatible_node(NULL,NULL,DEVNAME);
	if (np == NULL)
	{
		printk (KERN_INFO "node %s is not defined in DTS\n",DEVNAME );

		return 0;
	}
	irq  = irq_of_parse_and_map(np, 0); /* get IRQ # from device tree */


	dev = kzalloc(sizeof(struct device), GFP_KERNEL);
	
	
	dev_set_name(dev,DEVNAME);
	dev->release = my_release;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result" 
	(void)device_register(dev);
#pragma GCC diagnostic pop 

	info = kzalloc(sizeof(struct uio_info), GFP_KERNEL);
	info->name = DEVNAME;
	info->version = "0.0.1";
	info->irq = irq;
	info->irq_flags = IRQF_SHARED;
	info->handler = my_handler;



	if (uio_register_device(dev, info) < 0) {
		device_unregister(dev);
		kfree(dev);
		kfree(info);
		pr_info("Failing to register uio device\n");
		return -1;
	}
	
	pr_info("Registered UIO handler for IRQ=%d\n", irq);
	return 0;
}

static void __exit my_exit(void)
{
	uio_unregister_device(info);
	device_unregister(dev);
	pr_info("Un-Registered UIO handler for IRQ=%d\n", irq);
	kfree(info);
	kfree(dev);
}

module_init(my_init);
module_exit(my_exit);

MODULE_AUTHOR("Yair Gadelov");
MODULE_DESCRIPTION("axi gpio for zynq");
MODULE_LICENSE("GPL v2");
```

makefile to build:
```make
obj-m := uiofpga.o

SRC := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC)

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

clean:
	rm -f *.o *~ core .depend .*.cmd *.ko *.mod.c
	rm -f Module.markers Module.symvers modules.order
	rm -rf .tmp_versions Modules.symvers
```

## The device tree
```bash
/ {
	...

	fit_uio:fit  {
		status = "okay";
		compatible = "fix-interval-timer-irq";
		interrupt-parent = <&intc>;
                interrupts = <0 29 1>;
	};

	...
}

```
Here is what the three numbers assigned to “interrupt" means:

* The first value is a flag indicating if the interrupt is an SPI (shared peripheral interrupt). A nonzero value means it is an SPI.

* The second number relates to the IRQ number. For Shared Periperal interrupts, the value in the device tree is the (IRQ - 32), eg. subtract 32 from the IRQ number. See Chapter 7  table 7.4 of  the Zynq tech ref manual (ug-585) to understand the interrupt numbers. I guss it becase the fitst bit of SPI ( Shared Peripheral Interrupts) is mapped to IRQ 32. I mapped the FIT to 61 (32+29) - The first bit among the 16 bits of the of the shared interrupt port from the PL. This is q quote from UG-585 P. 229:
>A group of approximately 60 interrupts from various modules can be routed to one or both of the
>CPUs or the PL. The interrupt controller manages the prioritization and reception of these interrupts for the CPUs.
>Except for IRQ #61 through #68 and #84 through #91, all interrupt sensitivity types are fixed by the
>requesting sources and cannot be changed. The GIC must be programmed to accommodate this. The
>boot ROM does not program these registers; therefore the SDK device drivers must program the GIC
>to accommodate these sensitivity types.

* The third number is the IRQ type:
 	1 = low-to-high edge triggered
        2 = high-to-low edge triggered
        4 = active high level-sensitive
        8 = active low level-sensitive






## simple test application:
HEre is a demo how to recevive and response for interrupts from the FIT in user space.  I have configure the FIT to interrupt every 61 useconds and most of the times it deffently looks accurate. 
```bash
 61.000000   61.000000   61.000000   61.000000   63.000000   60.000000   61.000000   60.000000   61.000000   88.000000   37.000000   60.000000   60.000000   61.000000   61.000000   61.000000   62.000000   60.000000   61.000000   61.000000   61.000000   63.000000   60.000000   61.000000   60.000000   61.000000   61.000000   61.000000   61.000000   62.000000   61.000000   61.000000   61.000000   60.000000   62.000000   60.000000   62.000000   61.000000   63.000000   59.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   61.000000   62.000000   62.000000   60.000000   60.000000   62.000000   63.000000   59.000000
```

```c
int fd;
int trigger_init(void)
{

	fd=open("/dev/uio0",O_RDONLY);
	if (fd<0) {
		return -1;
	}

	return 0;
}
int trigger_poll(void)
{
	int info = 1,nb; /* unmask */

	struct pollfd fds = {
            .fd = fd,
            .events = POLLIN,
        };

        int ret = poll(&fds, 1, 100);

	if (ret >= 1) {
            nb = read(fd, &info, sizeof(info));
            if (0 && nb == (ssize_t)sizeof(info)) {
                /* Do something in response to the interrupt. */
                printf("Interrupt #%u!\n", info);
            }
        } else {
	    info = -1;
            close(fd);
        }


	return info;

}
```
The number of interrupt occurabce can be displayed by typping *cat /proc/interrupts*
```bash
           CPU0       CPU1       
 16:          1          0     GIC-0  27 Edge      gt
 17:          0          0     GIC-0  43 Level     ttc_clockevent
 18:     617543     758201     GIC-0  29 Edge      twd
 19:          0          0     GIC-0  37 Level     arm-pmu
 20:          0          0     GIC-0  38 Level     arm-pmu
 21:         43          0     GIC-0  39 Level     f8007100.adc
 24:          0          0     GIC-0  35 Level     f800c000.ocmc
 25:        397          0     GIC-0  82 Level     xuartps
 26:     397868          0     GIC-0  54 Level     eth0
 27:          0          0     GIC-0  45 Level     f8003000.dmac
 28:          0          0     GIC-0  46 Level     f8003000.dmac
 29:          0          0     GIC-0  47 Level     f8003000.dmac
 30:          0          0     GIC-0  48 Level     f8003000.dmac
 31:          0          0     GIC-0  49 Level     f8003000.dmac
 32:          0          0     GIC-0  72 Level     f8003000.dmac
 33:          0          0     GIC-0  73 Level     f8003000.dmac
 34:          0          0     GIC-0  74 Level     f8003000.dmac
 35:          0          0     GIC-0  75 Level     f8003000.dmac
 36:          0          0     GIC-0  40 Level     f8007000.devcfg
 42:          0          0     GIC-0  41 Edge      f8005000.watchdog
 43:    3478435          0     GIC-0  61 Edge      fix-intervel-timer-irq   <-- The number of FIT interrupts occurances
```

## References
[[1] https://www.kernel.org/doc/html/v4.13/driver-api/uio-howto.html](https://www.kernel.org/doc/html/v4.13/driver-api/uio-howto.html)  
[[2] http://fpga.org/2013/05/28/how-to-design-and-access-a-memory-mapped-device-part-two](http://fpga.org/2013/05/28/how-to-design-and-access-a-memory-mapped-device-part-two)  
[[3] https://elinux.org/images/b/b0/Uio080417celfelc08.pdf](https://elinux.org/images/b/b0/Uio080417celfelc08.pdf)  
[[4] https://www.osadl.org/fileadmin/dam/rtlws/12/Koch.pdf](https://www.osadl.org/fileadmin/dam/rtlws/12/Koch.pdf)   
[[5] https://www.kernel.org/doc/html/v4.14/driver-api/uio-howto.html](https://www.kernel.org/doc/html/v4.14/driver-api/uio-howto.html)  
[[6] https://www.xilinx.com/support/answers/62363.html](https://www.xilinx.com/support/answers/62363.html)  
[[7] https://yurovsky.github.io/2014/10/10/linux-uio-gpio-interrupt.html](https://yurovsky.github.io/2014/10/10/linux-uio-gpio-interrupt.html)  
[[8] https://www.slideshare.net/chrissimmonds/quick-and-easy-device-drivers-for-embedded-linux-using-uio](https://www.slideshare.net/chrissimmonds/quick-and-easy-device-drivers-for-embedded-linux-using-uio)  




