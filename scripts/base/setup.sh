#!/bin/bash -ex

useradd -m -s /bin/bash -G sudo dlink
echo 'dlink:dns320' | chpasswd

echo "127.0.1.1       $(cat /etc/hostname)" >> /etc/hosts

dpkg-reconfigure --frontend=noninteractive locales
update-locale en_US.UTF-8

dpkg-reconfigure --frontend=noninteractive tzdata
#timedatectl set-timezone Europe/Paris
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Fix "Warning: fsck not present, so skipping root file system" on boot
# Because /usr/share/initramfs-tools/hooks/fsck doesn't work as expected, copy fsck executables in initramfs
# Set explicitely FSTYPE=ext2,ext3,ext4 in /etc/initramfs-tools/initramfs.conf
# Alternatively but not tested: https://forum.armbian.com/topic/11207-include-fsck-on-a-init-ramdisk-espressobin/#comment-84245
sed -i s'/^FSTYPE=.*$/FSTYPE=ext2,ext3,ext4/' /etc/initramfs-tools/initramfs.conf

# Build u-boot images for already installed kernel
dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)

# mkdir -p /mnt/HD/HD_a2 /mnt/HD/HD_b2 /mnt/HD_a4 /mnt/HD_b4
# chmod -R a+rw /mnt/HD/HD_a2 /mnt/HD/HD_b2 /mnt/HD_a4 /mnt/HD_b4

wget https://github.com/ggirou/dns-nas-utils/releases/download/v1.5-1/dns-nas-utils.deb
dpkg -i dns-nas-utils.deb
rm dns-nas-utils.deb

# Avoid "lockd: cannot monitor" with NFS  https://bugs.launchpad.net/ubuntu/+source/nfs-utils/+bug/1689777
# systemctl enable rpc-statd

apt-get clean
rm /tmp/* /var/tmp/* /var/lib/apt/lists/*   /var/cache/debconf/* /var/log/*.log || true
