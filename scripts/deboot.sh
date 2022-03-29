#!/bin/bash -ex

# https://www.debian.org/releases/bullseye/armel/apds03.en.html

arch=$1
suite=$2
mirror=$3

hostname=DNS-320

# https://wiki.debian.org/BusterPriorityRequalification
# --variant=minbase
# dpkg-query -f '${binary:Package} ${Priority}\n' -W | grep -w 'required\|important'

# * Mandatory
packages=(
  # Kernel / DNS-320
  linux-image-marvell # * Linux for Marvell Kirkwood/Orion (meta-package)
  device-tree-compiler # * Device Tree Compiler for Flat Device Trees

  # Admin
  cron # process scheduling daemon
  dbus-user-session # * simple interprocess messaging system (systemd --user integration)
  hdparm # * tune hard disk parameters for high performance
  htop # interactive processes viewer
  iotop # simple top-like I/O monitor
  mtd-utils # * Memory Technology Device Utilities
  procps # /proc file system utilities
  u-boot-tools # * companion tools for Das U-Boot bootloader
  udev # /dev/ and hotplug management daemon

  # Localization
  locales # * GNU C Library: National Language (locale) data [support]
  tzdata # * time zone and daylight-saving time data

  # Misc
  ca-certificates # Common CA certificates

  # Network
  avahi-daemon # Avahi mDNS/DNS-SD daemon
  ifupdown # high level tools to configure network interfaces
  iputils-ping # Tools to test the reachability of network hosts
  isc-dhcp-client # DHCP client for automatically obtaining an IP address
  net-tools # NET-3 networking toolkit
  netbase # Basic TCP/IP networking system
  # ntpdate # client for setting system time from NTP servers (deprecated)
  sntp # Network Time Protocol - sntp client

  # Network - Servers
  netatalk # Basic TCP/IP networking system
  nfs-kernel-server # support for NFS kernel server
  openssh-server # secure shell (SSH) server, for secure access from remote machines
  samba # SMB/CIFS file, print, and login server for Unix

  # Python
  python3-minimal # minimal subset of the Python language (default python3 version)

  # Shells
  bash-completion # programmable completion for the bash shell

  # Utils
  acl # access control list - utilities
  busybox # Tiny utilities for small and embedded systems
  console-data # keymaps, fonts, charset maps, fallback tables for 'kbd'.
  curl # command line tool for transferring data with URL syntax
  dialog # Displays user-friendly dialog boxes from shell scripts
  fdisk # collection of partitioning utilities
  gnupg # GNU privacy guard - a free PGP replacement
  nano # small, friendly text editor inspired by Pico
  sudo # Provide limited super user privileges to specific users
  wget # retrieves files from the web
)

mkdir -p /chroot

if [ -f /dist/$suite-$arch.tar ]; then
    echo 'Untar existing deboostrap'
    tar xf /dist/$suite-$arch.tar -C /chroot
else
    echo 'Run deboostrap'

    function join { local IFS="$1"; shift; echo "$*"; }
    include=$(join , ${packages[@]})
    echo $include

    # apt update && apt-cache search "^($(join \| ${packages[@]}))$"

    debootstrap --arch=$arch --variant=minbase --include=$include $suite /chroot $mirror \
       || (cp /chroot/debootstrap/debootstrap.log /dist && exit 1)
    tar cf /dist/$suite-$arch.tar -C /chroot/ .
fi

ls -la /chroot

echo $hostname > /chroot/etc/hostname
echo "127.0.1.1       $hostname" >> /chroot/etc/hosts
echo LANG=en_US.UTF-8 > /chroot/etc/default/locale
echo en_US.UTF-8 UTF-8 >> /chroot/etc/locale.gen

cat <<EOF > /chroot/etc/network/interfaces.d/eth0
auto eth0
iface eth0 inet dhcp
EOF

# Autorepair option for fsck on boot https://manpages.debian.org/bullseye/initscripts/rcS.5.en.html
# Replaced by? https://manpages.debian.org/bullseye/systemd/systemd-fsck.8.en.html
# Check logs in /run/initramfs/fsck.log
echo 'FSCKFIX=yes' > /chroot/etc/default/rcS

cat <<'EOF' > /chroot/etc/fstab
# <file system>                           <mount point>         <type>  <options>          <dump>  <pass>
/dev/root   /       auto    noatime                 0 1
tmpfs       /tmp    tmpfs   nodev,nosuid,size=32M   0 0
# Uncomment if you have a second partition on your usb disk
#/dev/disk/by-path/platform-f1050000.ehci-usb-0:1:1.0-scsi-0:0:0:0-part2   /mnt/ssd/  ext4    nofail,auto,defaults,relatime     0 0
/dev/disk/by-path/platform-f1080000.sata-ata-1-part2   /mnt/HD/HD_a2/  ext3    nofail,auto,defaults,relatime     0 0
/dev/disk/by-path/platform-f1080000.sata-ata-2-part2   /mnt/HD/HD_b2/  ext3    nofail,auto,defaults,relatime     0 0
EOF

# HDD Hibernate
cat <<'EOF' >> /chroot/etc/hdparm.conf
# Not tested, is it useful?
# Disable Power Management for disk on usb
# /dev/disk/by-path/platform-f1050000.ehci-usb-0:1:1.0-scsi-0:0:0:0 {
#   apm = 255
# }

/dev/disk/by-path/platform-f1080000.sata-ata-1 {
    # Hibernate after 5min (5s * 60)
    spindown_time = 60
}

/dev/disk/by-path/platform-f1080000.sata-ata-2 {
    # Hibernate after 5min (5s * 60)
    spindown_time = 60
}
EOF

# TODO https://www.troublenow.org/752/debian-10-add-rc-local/
# Power-recovery
cat <<EOF > /chroot/etc/rc.local
#!/bin/sh -e

echo 37 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio37/direction
echo 1 > /sys/class/gpio/gpio37/value
EOF
chmod +x /chroot/etc/rc.local

# Build u-boot image whenever a new kernel is installed
# https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842374/U-Boot+Images#U-BootImages-FlattenedImageTree
# Quick test from DNS320 only
# /etc/kernel/postinst.d/zz-local-build-image $(uname -r)
# Full test (from DNS320 for UBIFS commands)
# dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)
cp /scripts/fit.its /chroot/boot
cat <<'EOF' > /chroot/etc/kernel/postinst.d/zz-local-build-image
#!/bin/sh -ex
# passing the kernel version is required
version="$1"
[ -z "${version}" ] && exit 0

cp /usr/lib/linux-image-${version}/kirkwood-dns320.dtb /boot/kirkwood-dns320.dtb

# Need device-tree-compiler
mkimage -f /boot/fit.its /boot/uImage-${version}

ln -sf /boot/uImage-${version} /boot/uImage

# Copy uImage to Nand UBIFS partition if exists
mkdir -p /tmp/ubifs
if [ -c /dev/mtd2 ]; then
  modprobe ubi
  ubiattach /dev/ubi_ctrl -m 2
  mount -t ubifs /dev/ubi0_0 /tmp/ubifs
  cp --backup --suffix .old /boot/uImage /tmp/ubifs/
  umount /tmp/ubifs
  ubidetach /dev/ubi_ctrl -m 2
fi
EOF
chmod a+x /chroot/etc/kernel/postinst.d/zz-local-build-image

cat <<'EOF' > /chroot/uEnv.txt
# Kernel command line parameters:
# https://www.kernel.org/doc/html/v5.10/admin-guide/kernel-parameters.html
# https://manpages.debian.org/bullseye/systemd/systemd-fsck.8.en.html
optargs=initramfs.runsize=32M usb-storage.delay_use=0 rootdelay=1 usbcore.autosuspend=-1 fsck.repair=preen
bootenvroot=/dev/disk/by-path/platform-f1050000.ehci-usb-0:1:1.0-scsi-0:0:0:0-part1 rw
bootenvrootfstype=ext2
ubifsloadimage=ubi part rootfs && ubifsmount ubi:rootfs && ubifsload ${loadaddr} /uImage || ubifsload ${loadaddr} /uImage.old
usbloadimage=ext4load usb 0:1 0xa00000 /boot/uImage && setenv loadaddr 0xa00000
bootenvcmd=run setbootargs; run usbloadimage || run ubifsloadimage; bootm ${loadaddr}
EOF

# All these modules will be stored in the initramfs and always loaded
# You may want some filesystems too, e.g. ext4
cat <<'EOF' >> /chroot/etc/initramfs-tools/modules
# If modified, run the following command:
# dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)
# For debugging only (doesn't recreate FIT file)
# update-initramfs -u -v
# Check content with:
# lsinitramfs /boot/initrd.img-$(uname -r)

# Thermal management
gpio-fan
kirkwood_thermal
# SATA
ehci_orion
sata_mv
# UBIFS
ubi
# Ethernet
mv643xx_eth
marvell
mvmdio
ipv6
# Power / USB buttons
evdev
gpio_keys
# USB disks
sd_mod
usb_storage
EOF

# Fix "Warning: fsck not present, so skipping root file system" on boot
# Because /usr/share/initramfs-tools/hooks/fsck doesn't work as expected, copy fsck executables in initramfs
# Set explicitely FSTYPE=ext2,ext3,ext4 in /etc/initramfs-tools/initramfs.conf
# Alternatively but not tested: https://forum.armbian.com/topic/11207-include-fsck-on-a-init-ramdisk-espressobin/#comment-84245
sed -i s'/^FSTYPE=.*$/FSTYPE=ext2,ext3,ext4/' /chroot/etc/initramfs-tools/initramfs.conf

cp /usr/bin/qemu-arm-static /chroot/usr/bin
chroot /chroot qemu-arm-static /bin/bash -ex <<'EOF'
useradd -m -s /bin/bash -G sudo dlink
echo 'dlink:dns320' | chpasswd

dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8

dpkg-reconfigure --frontend=noninteractive tzdata
#timedatectl set-timezone Europe/Paris
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Build u-boot images for already installed kernel
dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)

# mkdir -p /mnt/HD/HD_a2 /mnt/HD/HD_b2 /mnt/HD_a4 /mnt/HD_b4
# chmod -R a+rw /mnt/HD/HD_a2 /mnt/HD/HD_b2 /mnt/HD_a4 /mnt/HD_b4

wget https://github.com/ggirou/dns-nas-utils/releases/download/v1.5-1/dns-nas-utils.deb
dpkg -i dns-nas-utils.deb
rm dns-nas-utils.deb

# Avoid "lockd: cannot monitor" with NFS  https://bugs.launchpad.net/ubuntu/+source/nfs-utils/+bug/1689777
systemctl enable rpc-statd

apt-get clean
rm /tmp/* /var/tmp/* /var/lib/apt/lists/*   /var/cache/debconf/* /var/log/*.log || true
EOF
rm /chroot/usr/bin/qemu-arm-static

tar czf /dist/$suite-$arch.final.tar.gz -C /chroot/ .
cp /chroot/boot/uImage-* /dist/uImage

# Debugging
ls -lah /chroot/boot

cat /chroot/etc/hostname
cat /chroot/etc/default/locale
cat /chroot/etc/locale.gen | egrep '^[^#]'
cat /chroot/etc/timezone

cat /chroot/etc/fstab
cat /chroot/etc/kernel/postinst.d/zz-local-build-image
cat /chroot/etc/initramfs-tools/modules
