#!/bin/sh

arch=$1
suite=$2
mirror=$3

debootstrap --arch=$arch --include=openssh-server $suite /chroots/$suite-$arch $mirror

chroot /chroots/$suite-$arch sh -c "echo 'root:dlink' | chpasswd"
chroot /chroots/$suite-$arch sh -c "apt-key list | grep expired | cut -d'/' -f2 | cut -d' ' -f1 | xargs -l apt-key adv --recv-keys --keyserver keys.gnupg.net"

tar cf /chroots/$suite-$arch.tar -C /chroots/ $suite-$arch
rm -rf /chroots/$suite-$arch
cp -r /chroots/* /dist