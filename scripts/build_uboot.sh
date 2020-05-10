#!/bin/sh -ex

# https://github.com/u-boot/u-boot.git
# Original from https://gitlab.denx.de/u-boot/custodians/u-boot-marvell.git
[ -d u-boot ] || git clone -b v2020.04-dns320 https://github.com/ggirou/u-boot.git

cd u-boot
# git pull

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-
make distclean
make dns320_config
make u-boot.kwb
mv u-boot.lds u-boot.kwb u-boot.map u-boot-nodtb.bin u-boot.cfg u-boot.bin u-boot-dtb.bin u-boot /dist

# make cross_tools
