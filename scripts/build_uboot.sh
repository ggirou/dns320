#!/bin/sh -ex

# https://github.com/u-boot/u-boot.git
# Original from https://gitlab.denx.de/u-boot/custodians/u-boot-marvell.git
[ -d u-boot ] || git clone -b v2020.04-dns320 https://github.com/ggirou/u-boot.git

cd u-boot
git pull

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-
make distclean
make dns320_config
# make menuconfig
make u-boot.kwb
cp u-boot.kwb /dist

# make cross_tools

# Boot images > FIT + verbose message on fail + Set up board-specific details in device tree before boot
# CLI > Filesystem > ext4
# Partition > GPT
# Library routines -> Enable the FDT library for SPL
# Library routines -> Enable the FDT library for TPL


# CONFIG_OF_BOARD_SETUP : needs dev
