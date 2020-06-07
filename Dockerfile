FROM debian

RUN apt-get update \
    # Packages to debootstrap debian \
    && apt-get install -y debootstrap binfmt-support qemu qemu-user-static \
    # Packages to build u-boot \
    && apt-get install -y make gcc gcc-arm-none-eabi gcc-arm-linux-gnueabi gcc-x86-64-linux-gnux32 u-boot-tools git bison flex libncurses5-dev libncursesw5-dev
