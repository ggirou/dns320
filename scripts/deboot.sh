#!/bin/sh -ex

arch=$1
suite=$2
mirror=$3
include=$4

mkdir -p /chroot

[ -f /dist/$suite-$arch.tar ] \
  && tar xf /dist/$suite-$arch.tar -C /chroot \
  || debootstrap --arch=$arch --include=$include $suite /chroot $mirror

ls -la /chroot

tar cf /dist/$suite-$arch.tar -C /chroot/ .

cat <<EOF > /chroot/etc/fstab
/dev/root   /       auto    noatime                 0 0
tmpfs       /tmp    tmpfs   nodev,nosuid,size=32M   0 0
EOF

# Build u-boot images whenever a new kernel is installed
cat <<EOF > /chroot/etc/kernel/postinst.d/zz-local-build-image
#!/bin/sh -e
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
# Thermal management
gpio-fan
kirkwood_thermal
# SATA
ehci_orion
sata_mv
# Ethernet
mv643xx_eth
marvell
mvmdio
ipv6
# Power / USB buttons
evdev
gpio_keys
# USB disks
# sd_mod
# usb_storage
EOF

chroot /chroot bash <<EOF
echo 'root:dlink' | chpasswd
echo DNS-320 > /etc/hostname

echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
dpkg-reconfigure locales

# Build u-boot images for already installed kernel
dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)

apt-get clean
rm /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*.log
EOF
#chroot /chroot sh -c "apt-key list | grep expired | cut -d'/' -f2 | cut -d' ' -f1 | xargs -l apt-key adv --recv-keys --keyserver keys.gnupg.net"

tar czf /dist/$suite-$arch.final.tar.gz -C /chroot/ .


# L'argument mtdparts passé par u-boot au noyau a été renommé en cmdlinepart.mtdparts (détails dans le bug #831352).
