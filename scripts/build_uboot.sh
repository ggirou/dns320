#!/bin/sh -ex

#version=v2020.04
version=v2022.01
dir=/dist/u-boot

if [ ! -d $dir ]; then
  git clone -b $version https://github.com/u-boot/u-boot.git $dir
  cd $dir
else
  cd $dir
  git fetch
  git reset --hard tags/$version
fi

git config user.email "john@doe.xyz"; git config user.name "John Doe"

# Check what changes with similar DNS-325
# git diff tags/$oldVersion tags/$newVersion -- arch/arm/dts/kirkwood-dns* board/d-link/dns325/* configs/dns325* include/configs/dns325*

# Commands to recreate patch for a new version
# oldVersion=v2020.04 newVersion=v2022.01 patch=usbtimeoutfix
# oldVersion=v2020.04 newVersion=v2022.01 patch=dns320
# git checkout tags/$oldVersion; git checkout -b $oldVersion-$patch; git am --committer-date-is-author-date < ~/$oldVersion-$patch.patch
# git checkout tags/$newVersion; git merge --squash $oldVersion-$patch; # Resolve conflicts and report changes from DNS-325......
# git commit -m "$newVersion-$patch"; git format-patch --stdout HEAD~1 > ~/$newVersion-$patch.patch

# Apply `EHCI timed out on TD` patch from https://forum.doozan.com/read.php\?3,35295
git am --committer-date-is-author-date < /scripts/$version-usbtimeoutfix.patch
# Apply DNS-320 support patch from https://github.com/avoidik/board_dns320
git am --committer-date-is-author-date < /scripts/$version-dns320.patch

export ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
make distclean
make dns320_config
# make menuconfig

make u-boot.kwb

# make cross_tools

cp u-boot.kwb /dist
