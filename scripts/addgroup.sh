#!/bin/bash -ex

group=$1
users=$2

[ -z "$group" ] && echo Usage: $0 group \"user1 user2\" && exit

groupadd -K GID_MIN=2000 $group || true
[ -z "$users" ] || echo -n "$users" | xargs -d ' ' -l usermod -a -G  $group
