---
title: "Linux Gadget Device."
description: "Set up Linux device as human interface device or mass storage device."
tags : 
 - "usb"
 - "linux"
 - "stm32"

date : "2021-01-19"
archives : "2021"
categories : 
 - "linux"
 - "embedded"

draft: false
menu : "no-main"
---
This post is an example of making a USB device from a Linux embedded machine where any HOST can control it. From Linux [documention](https://www.kernel.org/doc/html/v4.17/driver-api/usb/gadget.html):

>Most Linux developers will not be able to use this API since they have USB host hardware in a PC, workstation, or server. Linux users with embedded systems are more likely to have USB peripheral hardware. To distinguish drivers running inside such hardware from the more familiar Linux “USB device drivers,” which are host-side proxies for the real USB devices, a different term is used: the drivers inside the peripherals are “USB gadget drivers.” In USB protocol interactions, the device driver is the master (or “client driver”) and the gadget driver is the slave (or “function driver”).

I will use stm32mp157 EVK board to demonstrate using Linux USB gadget API and define the Linux device as a mass storage drive and keyboard on the same USB OTG device. This EVB has a CPU named stm32mp157. 

## config Kernel modules
It has to config the following module Mass storae driver in the Liunx kernel:
```bash
Symbol: USB_MASS_STORAGE [=m]                                             
   Type  : tristate                                                          
   Prompt: Mass Storage Gadget                                               
     Location:                                                               
       -> Device Drivers                                                     
         -> USB support (USB_SUPPORT [=y])                                   
           -> USB Gadget Support (USB_GADGET [=y])                           
             -> USB Gadget precomposed configurations (<choice> [=m])        
     Defined at drivers/usb/gadget/legacy/Kconfig:240                        
     Depends on: <choice> && BLOCK [=y]                                      
     Selects: USB_LIBCOMPOSITE [=y] && USB_F_MASS_STORAGE [=y]
```
 ans also the folloinwg HID driver:
 ```bash
   Symbol: USB_G_HID [=m]                                                                                               
   Type  : tristate                                                                                                     
   Prompt: HID Gadget                                                                                                   
     Location:                                                                                                          
       -> Device Drivers                                                                                                
         -> USB support (USB_SUPPORT [=y])                                                                              
           -> USB Gadget Support (USB_GADGET [=y])                                                                      
             -> USB Gadget precomposed configurations (<choice> [=m])                                                   
     Defined at drivers/usb/gadget/legacy/Kconfig:431                                                                   
     Depends on: <choice>                                                                                               
     Selects: USB_LIBCOMPOSITE [=y] && USB_F_HID [=y] 
 ```

## Config USB Device though configfs
The config is a subsystem at the Linux kernel, and it allows to define a USB device. The Linux device has a USB device connection, and it is defined as the following with one configuration and two functions within it:  
1. USB mass storage - turns the Linx device to Disk On Key.  
2. HID - turns the Linux device into a keyboard.  


```bash
modprobe configfs
modprobe libcomposite
mount -t configfs none /sys/kernel/config
cd /sys/kernel/config/usb_gadget
mkdir g1
cd g1
echo "64" > bMaxPacketSize0
echo "0x200" > bcdUSB
echo "0x100" > bcdDevice
echo "0x1234" > idVendor
echo "0x5678" > idProduct
mkdir strings/0x409
mkdir configs/c1.1
echo "Demo USB gadget device" > strings/0x409/manufacturer
echo "Product" > strings/0x409/product
echo 0 > strings/0x409/serialnumber
mkdir configs/c1.1/strings/0x409/ -p
echo "Product Configuration " > configs/c1.1/strings/0x409/configuration
echo 120 > configs/c1.1/MaxPower


# mass storage configuration
modprobe usb_f_mass_storage
mkdir functions/mass_storage.ms0
echo /home/root/fat.fs > functions/mass_storage.ms0/lun.0/file
echo 1 > functions/mass_storage.ms0/lun.0/removable
ln -s functions/mass_storage.ms0 configs/c1.1

# hid keyboard
#mkdir functions/hid.0
echo 1 > functions/hid.0/protocol                      #  set the HID protocol
echo 1 > functions/hid.0/subclass                      #  set the device subclass
echo 8 > functions/hid.0/report_length                 #  set the byte length of HID reports
cat "/path/to/stdard/hid/keyabort/report/descripor.bin" > functions/hid.0/report_desc        
ln -s functions/hid.0 configs/c1.1 

# enable the USB device contoller
echo "49000000.usb-otg" > UDC
```

The utility [usbhid-dump](https://github.com/DIGImend/usbhid-dump) can help one get the HID device's report descriptor. In Gentoo, type:
```bash
emerge usbutils
```
Here is a report descriptor of keyboard.
```c
	0x05, 0x01,        // Usage Page (Generic Desktop Ctrls)
	0x09, 0x06,        // Usage (Keyboard)
	0xA1, 0x01,        // Collection (Application)
	0x05, 0x07,        //   Usage Page (Kbrd/Keypad)
	0x19, 0xE0,        //   Usage Minimum (0xE0)
	0x29, 0xE7,        //   Usage Maximum (0xE7)
	0x15, 0x00,        //   Logical Minimum (0)
	0x25, 0x01,        //   Logical Maximum (1)
	0x75, 0x01,        //   Report Size (1)
	0x95, 0x08,        //   Report Count (8)
	0x81, 0x02,        //   Input (Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position)
	0x95, 0x01,        //   Report Count (1)
	0x75, 0x08,        //   Report Size (8)
	0x81, 0x03,        //   Input (Const,Var,Abs,No Wrap,Linear,Preferred State,No Null Position)
	0x95, 0x05,        //   Report Count (5)
	0x75, 0x01,        //   Report Size (1)
	0x05, 0x08,        //   Usage Page (LEDs)
	0x19, 0x01,        //   Usage Minimum (Num Lock)
	0x29, 0x05,        //   Usage Maximum (Kana)
	0x91, 0x02,        //   Output (Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position,Non-volatile)
	0x95, 0x01,        //   Report Count (1)
	0x75, 0x03,        //   Report Size (3)
	0x91, 0x03,        //   Output (Const,Var,Abs,No Wrap,Linear,Preferred State,No Null Position,Non-volatile)
	0x95, 0x06,        //   Report Count (6)
	0x75, 0x08,        //   Report Size (8)
	0x15, 0x00,        //   Logical Minimum (0)
	0x25, 0x65,        //   Logical Maximum (101)
	0x05, 0x07,        //   Usage Page (Kbrd/Keypad)
	0x19, 0x00,        //   Usage Minimum (0x00)
	0x29, 0x65,        //   Usage Maximum (0x65)
	0x81, 0x00,        //   Input (Data,Array,Abs,No Wrap,Linear,Preferred State,No Null Position)
	0xC0,              // End Collection
```


Here is how to create an image that will serve as a storage place for the mass storage device:
```bash
# how big do you want the filesystem; specify it as SIZE * 1024.
dd if=/dev/zero of=fat.fs bs=1024 count=SIZE 
# formats the file as the filesystem FAT.
mkfs.vfat ./fat.fs
# to access the file system on a Linux Machine:
mount -o loop  fat.fs /mnt mounts fat.fs to /mnt.
```



## References
[[1] https://blog.soutade.fr/post/2016/07/create-your-own-usb-gadget-with-gadgetfs.html ](https://blog.soutade.fr/post/2016/07/create-your-own-usb-gadget-with-gadgetfs.html)  
[[2] https://github.com/qlyoung/keyboard-gadget/blob/master/gadget-setup.sh](https://github.com/qlyoung/keyboard-gadget/blob/master/gadget-setup.sh)  
[[3] https://elinux.org/images/8/81/Useful_USB_Gadgets_on_Linux.pdf](https://elinux.org/images/8/81/Useful_USB_Gadgets_on_Linux.pdf)  
[[4] https://stackoverflow.com/questions/21606991/custom-hid-device-hid-report-descriptor](https://stackoverflow.com/questions/21606991/custom-hid-device-hid-report-descriptor)
