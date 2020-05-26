#!/bin/sh -ex

arch=$1
suite=$2
mirror=$3

include="linux-image-marvell,device-tree-compiler,openssh-server,sudo,locales,tzdata,ntpdate,console-data,gnupg,apt-transport-https,ca-certificates,curl,nano,udev,dialog,ifupdown,mtd-utils,procps,iputils-ping,isc-dhcp-client,wget,netbase,net-tools,acl,openssh-server,avahi-daemon,python-minimal,u-boot-tools,hdparm,samba"
hostname=DNS-320

mkdir -p /chroot

[ -f /dist/$suite-$arch.tar ] \
  && tar xf /dist/$suite-$arch.tar -C /chroot \
  || (debootstrap --arch=$arch --include=$include $suite /chroot $mirror \
      && tar cf /dist/$suite-$arch.tar -C /chroot/ .)

ls -la /chroot

echo $hostname > /chroot/etc/hostname
echo "127.0.1.1       $hostname" >> /chroot/etc/hosts
echo LANG=en_US.UTF-8 > /chroot/etc/default/locale
echo en_US.UTF-8 UTF-8 >> /chroot/etc/locale.gen
echo "Europe/Paris" > /chroot/etc/timezone

cat <<EOF > /chroot/etc/network/interfaces.d/eth0
auto eth0
iface eth0 inet dhcp
EOF

cat <<'EOF' > /chroot/etc/fstab
/dev/root   /       auto    noatime                 0 0
tmpfs       /tmp    tmpfs   nodev,nosuid,size=32M   0 0
/dev/disk/by-path/platform-f1080000.sata-ata-1-part2   /mnt/HD/HD_a2/  ext3    rw,relatime     0 0
/dev/disk/by-path/platform-f1080000.sata-ata-2-part2   /mnt/HD/HD_b2/  ext3    rw,relatime     0 0
EOF

# HDD Hibernate
cat <<'EOF' >> /chroot/etc/hdparm.conf
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
cp fit.its /chroot/boot
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
mkdir -p /mnt/ubifs
[ -c /dev/mtd2 ] \
  && modprobe ubi \
  && ubiattach /dev/ubi_ctrl -m 2 \
  && mount -t ubifs /dev/ubi0_0 /mnt/ubifs \
  && cp --backup --suffix .old /boot/uImage /mnt/ubifs/ \
  && umount /mnt/ubifs \
  && ubidetach /dev/ubi_ctrl -m 2

EOF
chmod a+x /chroot/etc/kernel/postinst.d/zz-local-build-image

cat <<'EOF' > /chroot/uEnv.txt
optargs=initramfs.runsize=32M usb-storage.delay_use=0 rootdelay=1
bootenvroot=/dev/disk/by-path/platform-f1050000.ehci-usb-0:1:1.0-scsi-0:0:0:0-part1 rw
bootenvrootfstype=ext2
ubifsloadimage=ubi part rootfs && ubifsmount ubi:rootfs && ubifsload ${loadaddr} /uImage || ubifsload ${loadaddr} /uImage.old
# Because of flaky USB, load uImage in two parts with some delays
usbloadimage=sleep 5 && ext4load usb 0:1 0xa00000 /boot/uImage 0xa00000 && sleep 10 && ext4load usb 0:1 0x1400000 /boot/uImage 0 0xa00000 && setenv loadaddr 0xa00000
bootenvcmd=run setbootargs; run ubifsloadimage || run usbloadimage; bootm ${loadaddr}
EOF

# All these modules will be stored in the initramfs and always loaded
# You may want some filesystems too, e.g. ext4
cat <<'EOF' >> /chroot/etc/initramfs-tools/modules
# If modified, run the following command:
# dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)
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

chroot /chroot bash -ex <<'EOF'
useradd -m -s /bin/bash -G sudo dlink
echo 'dlink:dns320' | chpasswd

dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8

dpkg-reconfigure --frontend=noninteractive tzdata

# Build u-boot images for already installed kernel
dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)

# mkdir -p /mnt/HD/HD_a2 /mnt/HD/HD_b2 /mnt/HD_a4 /mnt/HD_b4
# chmod -R a+rw /mnt/HD/HD_a2 /mnt/HD/HD_b2 /mnt/HD_a4 /mnt/HD_b4

wget https://github.com/ggirou/dns-nas-utils/releases/download/v1.5-1/dns-nas-utils.deb
dpkg -i dns-nas-utils.deb
rm dns-nas-utils.deb

apt-get clean
rm /tmp/* /var/tmp/* /var/lib/apt/lists/*   /var/cache/debconf/* /var/log/*.log || true
EOF

tar czf /dist/$suite-$arch.final.tar.gz -C /chroot/ .

# Debugging
ls -lah /chroot/boot

cat /chroot/etc/hostname
cat /chroot/etc/default/locale
cat /chroot/etc/locale.gen | egrep '^[^#]'
cat /chroot/etc/timezone

cat /chroot/etc/fstab
cat /chroot/chroot/etc/kernel/postinst.d/zz-local-build-image
cat /chroot/etc/initramfs-tools/modules
