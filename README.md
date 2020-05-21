Run Debian on DNS320
--------------------

Everything here comes essentially from:

- https://jamie.lentin.co.uk/devices/dlink-dns325/ : great tutorials about how to boot Debian on DNS-320 and how to replace u-boot firmware
- https://github.com/avoidik/board_dns320 : patch files to build last version of u-boot for DNS-320

Other links:
- Firmwares and documentations: ftp://ftp.dlink.eu/Products/dns/dns-320/
- My original DLink firmware version: 2.03
- Wikis: http://dns323.kood.org/dns-320
- Linux kernel support: https://www.kernel.org/doc/html/latest/arm/marvel.html
- U-Boot:
  - http://www.denx.de/wiki/U-Boot
  - https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842374/U-Boot+Images

> **DISCLAIMER NOTICE**
> * I'm not responsible for bricked devices, dead SD cards, thermonuclear war, or you getting fired because the alarm app failed (like it did for me...).
> * YOU are choosing to make these modifications, and if you point the finger at me for messing up your device, I will laugh at you.
> * Your warranty will be void if you tamper with any part of your device / software.
> 😘

If you want to:

- Only run chrooted Debian Squeeze from USB key using fun_plug, follow [those instructions](fun_plug.md)
- RECOMMANDED FIRST: Boot Debian from USB key keeping original U-Boot (needs Serial Port use), follow [those instructions](keep_uboot.md)
- Boot Debian from USB key with lastest U-Boot (needs Serial Port use), follow instructions below.

-----------------------------------------------------------------------

# Deboostrap debian

    docker-compose run deboot

> For Debugging/Testing:
>
>     docker-compose run deboot bash
>     ./deboot.sh armel buster http://ftp.fr.debian.org/debian/ openssh-server

# Get USB key ready

## Format to ext2
    
    # Optionnal, recreate MBR partition
    sudo apt-get install mbr
    sudo install-mbr /dev/sda

    # Create and formate axt2 partition
    # echo ";" | sudo sfdisk /dev/sda
    sudo parted -l
    sudo parted /dev/sda rm 1
    sudo parted /dev/sda mklabel msdos
    sudo parted -a optimal /dev/sda mkpart primary 0% 100%
    #sudo parted -a minimal /dev/sda mkpart primary 0% 100%
    sudo parted /dev/sda set 1 boot on

    sudo mkfs.ext2 /dev/sda1

    # Optionnal, chek bad blocks and fix it
    sudo badblocks -s -w -t 0 /dev/sda1 > badsectors.txt
    sudo e2fsck -y -l badsectors.txt /dev/sda1

## Extract Debian

    sudo mkdir -p /mnt/usb/
    sudo mount /dev/sda1 /mnt/usb/
    sudo tar xzf ~/buster-armel.final.tar.gz -C /mnt/usb/
    ls -la /mnt/usb/
    sudo umount /mnt/usb/

> Only boot files (FIXME Not working...):
>
>     sudo tar xzf ~/buster-armel.final.tar.gz -C /mnt/usb/ boot

-----------------------------------------------------------------------

# Build U-Boot

    docker-compose run uboot

> Debugging/testing
>
>     docker-compose run uboot bash
>     ./build_uboot.sh

# Serial boot

    screen -L /dev/ttyUSB0 115200

At the `Hit any key to stop autoboot` prompt, press `space` then `1` (can be done before). You should see u-boot prompt:

    Marvel>> 

First, keep current u-boot parameters:

    printenv

> Keep the content of `printenv` [output](infos/printenv.txt). This will be a useful reference if you want to restore any u-boot parameters.

# Test new U-Boot with Serial port

> **NB:** Newer stock versions of u-boot cannot boot the original D-link kernels!

    sudo apt-get install u-boot-tools
    kwboot -p -b u-boot.kwb -B115200 -t /dev/ttyUSB0

> From Marwell console, add delays with ping before reboot, so you can switch serial to kwboot
>
>     ping 1;ping 1;reset

Try to boot with following commands :

    setenv ethaddr 14:D6:4D:AB:A7:12
    setenv loadbootenv ext2load usb 0:1 ${loadaddr} ${bootenv}
    boot

> New default boot commands try to load `uEnv.txt` from USB FAT partition, just change `loadbootenv` to load from ext2.

## `uEnv.txt` examples

### To boot with new Flat Image Tree (FIT)

> See `/etc/kernel/postinst.d/zz-local-build-image` created by [`deboot.sh`](scripts/deboot.sh) to know how to build FIT uImage

    optargs=initramfs.runsize=32M usb-storage.delay_use=0 rootdelay=1
    bootenvroot=/dev/disk/by-path/platform-f1050000.ehci-usb-0:1:1.0-scsi-0:0:0:0-part1 rw
    bootenvrootfstype=ext2
    # Because of flaky USB, load uImage in two parts with some delays
    bootenvcmd=run setbootargs;sleep 5;ext4load usb 0:1 0xa00000 /boot/uImage 0xa00000;sleep 10;ext4load usb 0:1 0x1400000 /boot/uImage 0 0xa00000;bootm 0xa00000

> Notes:  
> Because of a bug with `ext2load`, it doesn't work with `pos` argument, use `ext4load` instead...  
>
> USB boot root works with `usbbootargs_root root=/dev/sda1 rw` if no disks.  
> With disks it's not sure usb key will be affected to `sda`.  
> Use full path to be sure.
>
> `initramfs.runsize` 10% by default, fit it to 32M  
> The mtdparts option had became cmdlinepart.mtdparts (in Debian-land, at least). [StackExchange](https://unix.stackexchange.com/q/554266)

### To boot with legacy images

    optargs=initramfs.runsize=32M usb-storage.delay_use=0 rootdelay=1
    bootenvroot=/dev/disk/by-path/platform-f1050000.ehci-usb-0:1:1.0-scsi-0:0:0:0-part1 rw
    bootenvrootfstype=ext2
    # Because of flaky USB, load images with some delays
    bootenvcmd=run setbootargs;sleep 5;ext2load usb 0:1 0xa00000 /boot/uImage;sleep 10;ext2load usb 0:1 0xf00000 /boot/uInitrd;sleep 5;bootm 0xa00000 0xf00000

# Persist new u-boot

If everything is OK, copy `u-boot.kwb` to USB key, then:

    usb reset ; ext2load usb 0:1 0x1000000 /u-boot.kwb
    nand erase 0x000000 0xe0000
    nand write 0x1000000 0x000000 0xe0000
    reset

First, keep current new u-boot parameters:

    printenv

> Keep the content of `printenv` [output](infos/printenv.txt). This will be a useful reference if you want to restore any u-boot parameters.

Reset env ands save them:

    setenv ethaddr 14:D6:4D:AB:A7:12
    setenv loadbootenv ext2load usb 0:1 ${loadaddr} ${bootenv}
    saveenv
    reset

# Load Images With U-Boot Via TFTP

Source: https://docs.khadas.com/vim3/LoadImagesWithUBootViaTFTP.html

    setenv ipaddr 192.168.1.1
    setenv serverip 192.168.1.2
    tftp 0x0a00000 uImage
    bootm 0x0a00000
