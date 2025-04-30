#!/bin/sh
export LFS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/rootfs"
umask 022
export PATH=$LFS/tools/bin:/usr/bin
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LC_ALL=POSIX
export CONFIG_SITE=$LFS/usr/share/config.site
export MAKEFLAGS=-j32