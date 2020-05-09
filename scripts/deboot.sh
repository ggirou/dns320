#!/bin/sh -ex

arch=$1
suite=$2
mirror=$3

include="linux-image-marvell,openssh-server,sudo,locales,tzdata,ntpdate,console-data,gnupg,apt-transport-https,ca-certificates,curl,nano,udev,dialog,ifupdown,mtd-utils,procps,iputils-ping,isc-dhcp-client,wget,netbase,net-tools,acl,openssh-server,avahi-daemon,python-minimal,u-boot-tools,hdparm,samba"
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

# Build u-boot images whenever a new kernel is installed
cat <<'EOF' > /chroot/etc/kernel/postinst.d/zz-local-build-image
#!/bin/sh -ex
# passing the kernel version is required
version="$1"
[ -z "${version}" ] && exit 0

# NB: change depending on your NAS model
cat /boot/vmlinuz-${version} /usr/lib/linux-image-${version}/kirkwood-dns320.dtb \
    > /tmp/appended_dtb

/usr/bin/mkimage -A arm -O linux -T kernel -C none -n uImage \
                 -a 0x00008000 -e 0x00008000 \
                 -d /tmp/appended_dtb /boot/uImage-${version}
ln -sf /boot/uImage-${version} /boot/uImage

/usr/bin/mkimage -A arm -O linux -T ramdisk -C gzip -n uInitrd \
                 -a 0x00e00000 -e 0x00e00000 \
                 -d /boot/initrd.img-${version} /boot/uInitrd-${version}
ln -sf /boot/uInitrd-${version} /boot/uInitrd

rm /tmp/appended_dtb
EOF
chmod a+x /chroot/etc/kernel/postinst.d/zz-local-build-image

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
# Nand
orion_nand
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
