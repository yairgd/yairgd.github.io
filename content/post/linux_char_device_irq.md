---
title: "Linux char device to handle with IRQ "
description: "Linux char device to handle with IRQ"
tags : 
 - "linux"
 - "kernel"
 - "rt"

date : "2020-02-20"
archives : "2020"
categories : 
 - "linux"
 - "embbeded"

menu : "no-main"
---
# Linux chr device to handle with external irq

We have an external FPGA that triggers GPIO. To handle with the IRQ in userspace, it had to write a Linux chr device to handle the IRQ in the kernel space and to signalize the userspace using a standard system call. 

Here is the simple drive:

```c
#include <linux/module.h>
#include <linux/kernel.h>    /* printk() */
#include <linux/moduleparam.h>
#include <asm/uaccess.h>
#include <asm/pgtable.h>
#include <linux/fs.h>
#include <linux/gfp.h>
#include <linux/cdev.h>
#include <linux/sched.h>
#include <linux/interrupt.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/of_platform.h> 
#include <linux/semaphore.h>


DECLARE_WAIT_QUEUE_HEAD(hq);
static int irq_num;

static int x=0;
//spinlock_t mLock = SPIN_LOCK_UNLOCKED;
unsigned long flags;
static DEFINE_SPINLOCK(mLock);

static irqreturn_t fpga_irq_handle(int irq, void *dev_id)

{
	wake_up(&hq);
//	printk(KERN_DEBUG "Interrupt\n");
    	return IRQ_HANDLED;
}

	static ssize_t
fpga_read(struct file *file, char __user *buf,size_t count,loff_t *ppos)
{
	wait_event(hq,x);	
	return 0;
}

static struct file_operations fpga_fops =
{
	.owner = THIS_MODULE,
	.read = fpga_read,
};

static struct cdev *fpga_cdev;
#define DEVNAME "fpga-irq"
	static int
fpga_init (void)
{
	int  res;
	struct device_node * np = NULL;

	/* set IRQ */
	np = of_find_compatible_node(NULL,NULL,DEVNAME);
	if (np == NULL)
	{
		printk (KERN_INFO "node %s is not defined in DTS\n",DEVNAME );

		return 0;
	}
	irq_num = irq_of_parse_and_map(np, 0); /* get IRQ # from device tree */

	res = request_irq(irq_num, fpga_irq_handle, 0, DEVNAME,0  );
	if (res ) {
		printk (KERN_INFO "failed to request IRQ%u: %d\n",irq_num, res);
		return res;   

	}
	printk("OK to request IRQ: %u\n",irq_num);




	if(register_chrdev_region(MKDEV(230,0),1,"fpga"))
	{
		printk (KERN_INFO "alloc chrdev error.\n");
		return -1;
	}

	fpga_cdev=cdev_alloc();
	if(!fpga_cdev)
	{
		printk (KERN_INFO "cdev alloc error.\n");
		return -1;
	}
	fpga_cdev->ops = &fpga_fops;
	fpga_cdev->owner = THIS_MODULE;

	if(cdev_add(fpga_cdev,MKDEV(230,0),1))
	{
		printk (KERN_INFO "cdev add error.\n");
		return -1;
	}

	return 0;

}

static void
fpga_cleanup (void)
{

	printk (KERN_INFO "hello unloaded succefully.\n");
	free_irq(irq_num,fpga_irq_handle);

}

module_init (fpga_init);
module_exit (fpga_cleanup);
MODULE_LICENSE("GPL");
```



Makefile to buid the module:

```makefile
#C_INCLUDE_PATH=../zydis/include/Zydis
#CPATH=../zydis/include/Zydis
EXTRA_CFLAGS=

#-Wundef 
#-Wframe-larger-than=4096 -Wint-to-pointer-cast -mcmodel=kernel 
 

obj-m += fpga.o


disasm-objs +=  

all:
	make -C /path/to/kernel  M=$(PWD) ARCH=arm64 CROSS_COMPILE=/opt/fsl-imx-xwayland/4.14-sumo/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-   modules

clean:
	make -C /path/to/kernel M=$(PWD)  ARCH=arm64 CROSS_COMPILE=/opt/fsl-imx-xwayland/4.14-sumo/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-  modules  clean

```

Here is a test program which gets periodical IRQ. It open and wait for IRQ event and each event, it triggers another GPIO, which can see on a scope device.

```c
#include<stdio.h>
#include<fcntl.h>
#include<unistd.h>
#include<sys/ioctl.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <pthread.h>


void *thread_isr(void *p)
{
	char buf[100];
	int fd,led_fd;
	fd=open("/dev/fpga",O_RDONLY);
	led_fd=open("/sys/class/gpio/gpio100/value",O_WRONLY);

	while(1)
	{
		write(led_fd,"1",1);		
		read(fd,buf,1);
		write(led_fd,"0",1);
		usleep(400);
		
	//	printf("Interrupt handler\n");
		write(led_fd,"1",1);
		
		
	}

}

int main()
{
	pthread_t t1;
	puts("start");
	pthread_create(&t1,NULL,thread_isr,NULL);
	while (1)
		sleep(500);
	return 1;
}
```
to compile and copy the test to target run:
```bash
$CC test.c -o test -lpthread  -g -O2
scp test root@a.b.c.d:/home/root #a.b.c.d is the target ip address
```

the demo app triggers GPIOs to measure the response in scope and the following commands should be run before the test:
```bash
insmod fpga.ko
mknod /dev/fpga c 230 0
echo  100 > /sys/class/gpio/export 
echo "out" > /sys/class/gpio/gpio100/direction
echo 1 > /sys/class/gpio/gpio100/value
echo 0 > /sys/class/gpio/gpio100/value
```

# References
[[1] https://yurovsky.github.io/2014/10/10/linux-uio-gpio-interrupt.html](https://yurovsky.github.io/2014/10/10/linux-uio-gpio-interrupt.html)  
[[2] https://github.com/torvalds/linux/blob/master/drivers/uio/uio_pdrv_genirq.c](https://github.com/torvalds/linux/blob/master/drivers/uio/uio_pdrv_genirq.c)  
[[3] https://lwn.net/Articles/127293/](https://lwn.net/Articles/127293/)  
[[4] https://wiki.embeddedarm.com/wiki/Userspace_IRQ](https://wiki.embeddedarm.com/wiki/Userspace_IRQ)  
[[5] https://elinux.org/images/9/9b/GPIO_for_Engineers_and_Makers.pdf](https://elinux.org/images/9/9b/GPIO_for_Engineers_and_Makers.pdf)  
[[6] https://harmoninstruments.com/posts/uio.html](https://harmoninstruments.com/posts/uio.html)  
[[7] http://alvarom.com/2014/12/17/linux-user-space-drivers-with-interrupts](http://alvarom.com/2014/12/17/linux-user-space-drivers-with-interrupts)  
[[8] http://www.discoversdk.com/knowledge-base/interrupt-handling-in-user-space](http://www.discoversdk.com/knowledge-base/interrupt-handling-in-user-space)  
[[9] https://yurovsky.github.io/2014/10/10/linux-uio-gpio-interrupt.html](https://yurovsky.github.io/2014/10/10/linux-uio-gpio-interrupt.html)  
[[10] https://fpgacpu.wordpress.com/2013/05/28/how-to-design-and-access-a-memory-mapped-device-part-two/](https://fpgacpu.wordpress.com/2013/05/28/how-to-design-and-access-a-memory-mapped-device-part-two/)  
