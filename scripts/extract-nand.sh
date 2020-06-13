#!/bin/bash -ex

# orion_nand:1M(u-boot),5M(uImage),5M(ramdisk),102M(image),10M(mini_firmware),-(config)

# Begin - End - Size
# 0x00000   - 0x5c4b0   - 0x5c4b0 u-boot
# 0xa0000   - 0xc0000   - 0x20000 u-boot Env
# 0x100000  - 0x31bf68  - 0x21bf68 uImage
# 0x600000  - 0x7a7f58  - 0x1a7f58 ramdisk
# 0xb00000  - 0x25b7800 - 0x1ab7800 image.part
# 0xb00800  - 0x25b7800 - 0x1ab7000 image.shfs
# 0x7100000 - 0x77fb000 - 0x1fa800 mini_firmware.part
# 0x7100800 - 0x7310dd0 - 0x2105d0 mini_firmware.uImage
# 0x7400800 - 0x787F000 - 0x47e800 mini_firmware.ramdisk
# 0x7600800 - 0x77fb000 - 0x1fa800 mini_firmware.shfs.part
# 0x7601000 - 0x77fb000 - 0x1fa000 mini_firmware.shfs
# 0x7b00000 - 0x8000000 - 0x500000 config

[ -f mtd0.bin ] || dd if=/dev/mtd0 of=mtd0.bin bs=1M

mkdir -p out

[ -f out/u-boot.bin ]         || dd bs=1024 skip=0 count=$((1 * 1024)) if=mtd0.bin of=out/u-boot.bin
[ -f out/uImage.bin ]         || dd bs=1024 skip=$((1 * 1024)) count=$((5 * 1024)) if=mtd0.bin of=out/uImage.bin
[ -f out/ramdisk.bin ]        || dd bs=1024 skip=$((6 * 1024)) count=$((5 * 1024)) if=mtd0.bin of=out/ramdisk.bin
[ -f out/image.bin ]          || dd bs=1024 skip=$((11 * 1024)) count=$((102 * 1024)) if=mtd0.bin of=out/image.bin
[ -f out/mini_firmware.bin ]  || dd bs=1024 skip=$((113 * 1024)) count=$((10 * 1024)) if=mtd0.bin of=out/mini_firmware.bin
[ -f out/config.bin ]         || dd bs=1024 skip=$((123 * 1024)) count=$((5 * 1024)) if=mtd0.bin of=out/config.bin

[ -f out/image.shfs ]             || dd bs=1024 skip=2 if=out/image.bin of=out/image.shfs
[ -f out/mini_firmware.uImage ]   || dd bs=1024 skip=2 count=$((3 * 1024 - 2)) if=out/mini_firmware.bin of=out/mini_firmware.uImage
[ -f out/mini_firmware.ramdisk ]  || dd bs=1024 skip=$((3 * 1024 + 2)) count=$((2 * 1024 - 2)) if=out/mini_firmware.bin of=out/mini_firmware.ramdisk
[ -f out/mini_firmware.shfs ]     || dd bs=1024 skip=$((5 * 1024 + 4)) if=out/mini_firmware.bin of=out/mini_firmware.shfs

file out/*.bin

unsquashfs -s out/image.shfs
[ -d out/image ] || (mkdir -p out/image && unsquashfs -f -d out/image out/image.shfs)
# sudo mount -t squashfs -o loop out/image.shfs out/mini_firmware/

unsquashfs -s out/mini_firmware.shfs
[ -d out/mini_firmware ] || (mkdir -p out/mini_firmware && unsquashfs -f -d out/mini_firmware out/mini_firmware.shfs)
# sudo mount -t squashfs -o loop out/mini_firmware.shfs out/mini_firmware/

# sudo apt-get install -y mtd-utils
jffs2reader out/config.bin
jffs2reader out/config.bin -f /group
# sudo mount -t jffs2 -o loop out/config.bin out/config/
