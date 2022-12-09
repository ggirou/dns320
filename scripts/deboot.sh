#!/bin/bash -ex

# https://www.debian.org/releases/bullseye/armel/apds03.en.html

arch=$1
suite=$2
mirror=$3

# https://wiki.debian.org/BusterPriorityRequalification
# --variant=minbase
# dpkg-query -f '${binary:Package} ${Priority}\n' -W | grep -w 'required\|important'

# * Mandatory
packages=(
  # Kernel
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
  systemd-timesyncd # minimalistic service to synchronize local time with NTP servers

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
  zstd # fast lossless compression algorithm
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

    debootstrap --arch=$arch --include=$include $suite /chroot $mirror \
       || (cp /chroot/debootstrap/debootstrap.log /dist && exit 1)
    tar cf /dist/$suite-$arch.tar -C /chroot/ .
fi

ls -la /chroot

# Copy base files in chroot
cp -r /scripts/base/* /chroot

cp /usr/bin/qemu-arm-static /chroot/usr/bin
LANG=C.UTF-8 chroot /chroot qemu-arm-static /bin/bash -ex /setup.sh
rm /chroot/usr/bin/qemu-arm-static /chroot/setup.sh

tar czf /dist/$suite-$arch.final.tar.gz -C /chroot/ .
cp /chroot/vmlinuz /chroot/initrd.img /chroot/boot/uImage /dist

# Debugging
ls -lah /chroot/boot

cat /chroot/etc/hostname
cat /chroot/etc/default/locale
cat /chroot/etc/locale.gen | egrep '^[^#]'
cat /chroot/etc/timezone

cat /chroot/etc/fstab
cat /chroot/etc/kernel/postinst.d/zz-local-build-image
cat /chroot/etc/initramfs-tools/modules
