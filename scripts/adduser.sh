#!/bin/bash -ex

user=$1
groups=$2

[ -z $user ] && echo Usage: $0 username \"group1 group2\" && exit
[ -z $groups ] || groups="-G $groups"

useradd -m -s /bin/bash $groups $user
passwd $user
smbpasswd -a $user
