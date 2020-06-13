Original DNS-320 nand extraction
--------------------------------

Extracted with [extract-nand.sh](../scripts/extract-nand.sh).

DLink firmware version: 2.03

    orion_nand:1M(u-boot),5M(uImage),5M(ramdisk),102M(image),10M(mini_firmware),-(config)

| Begin     | End       | Real Size | Label
| --------- | --------- | --------- | ---
| 0x00000   | 0x5c4b0   | 0x5c4b0   | u-boot
| 0xa0000   | 0xc0000   | 0x20000   | u-boot Env
| 0x100000  | 0x31bf68  | 0x21bf68  | uImage
| 0x600000  | 0x7a7f58  | 0x1a7f58  | ramdisk
| 0xb00000  | 0xb00800  | 0x800     | image offset
| 0xb00800  | 0x25b7800 | 0x1ab7000 | image.shfs
| 0x7100000 | 0x7100800 | 0x800     | mini_firmware offset
| 0x7100800 | 0x7310dd0 | 0x2105d0  | mini_firmware.uImage
| 0x7400800 | 0x787F000 | 0x47e800  | mini_firmware.ramdisk
| 0x7600800 | 0x7601000 | 0x800     | mini_firmware.shfs offset
| 0x7601000 | 0x77fb000 | 0x1fa000  | mini_firmware.shfs
| 0x7b00000 | 0x8000000 | 0x500000  | config
