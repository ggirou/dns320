Boot Debian keeping original U-Boot
-----------------------------------

# Deboostrap debian

    docker-compose run deboot ./deboot_keepuboot.sh armel squeeze http://archive.debian.org/debian/

> For Debugging/Testing:
> 
>     docker-compose run deboot bash
>     ./deboot_keepuboot.sh armel buster http://ftp.fr.debian.org/debian/ openssh-server

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

> Only boot files (Not working...):
>
>     sudo tar xzf ~/buster-armel.final.tar.gz -C /mnt/usb/ boot

# Serial boot

    screen -L /dev/ttyUSB0 115200

At the `Hit any key to stop autoboot` prompt, press `space` then `1` (can be done before). You should see u-boot prompt:

    Marvel>> 

First, keep current u-boot parameters:

    printenv

> Keep the content of `printenv` [output](infos/printenv.txt). This will be a useful reference if you want to restore any u-boot parameters.

    setenv ethaddr 14:D6:4D:AB:A7:12
    setenv usbbootargs_root root=/dev/disk/by-path/platform-f1050000.ehci-usb-0:1:1.0-scsi-0:0:0:0-part1 rw
    setenv mtdparts mtdparts=orion_nand:1M(u-boot),5M(uImage),5M(ramdisk),102M(image),10M(mini_firmware),-(config)
    setenv bootargs console=ttyS0,115200 initramfs.runsize=32M usb-storage.delay_use=0 rootdelay=1 panic=5 ${usbbootargs_root} ${mtdparts} cmdlinepart.${mtdparts}
    # setenv bootargs console=ttyS0,115200 initramfs.runsize=32M usb-storage.delay_use=0 rootdelay=1 panic=5 ${usbbootargs_root}
    setenv bootcmd 'usb start;ext2load usb 0:1 0xa00000 /boot/uImage;ext2load usb 0:1 0xf00000 /boot/uInitrd;bootm 0xa00000 0xf00000'
    boot

If booting is ok, re-run all `setenv` commands above, re-check values, then persist:

    printenv ethaddr usbbootargs_root mtdparts cmdlinepart.mtdparts bootargs bootcmd
    saveenv
    reset

> Note:  
>
> USB boot root works with `usbbootargs_root root=/dev/sda1 rw` if no disks.  
> With disks it's not sure usb key will be affected to `sda`.  
> Use full path to be sure.
>
> `initramfs.runsize` 10% by default, fit it to 32M  
> The mtdparts option had became cmdlinepart.mtdparts (in Debian-land, at least). [StackExchange](https://unix.stackexchange.com/q/554266)
>
> `panic=Y` reboot on kernel panic. Happen when usb storage is not detected and default kernel is booted.

### Debug USB disk

    usb start
    usb info
    usb part
    ext2ls usb 0:1

To try another USB Key, restart:

    reset

Source: https://github.com/ValCher1961/McDebian_WRT3200ACM/wiki/%23-Using-external-drives-in-U-Boot

## Rollback

    setenv bootargs 'root=/dev/ram console=ttyS0,115200 :::DB88FXX81:egiga0:none'
    setenv bootcmd 'nand read.e 0xa00000 0x100000 0x300000;nand read.e 0xf00000 0x600000 0x300000;bootm 0xa00000 0xf00000'
