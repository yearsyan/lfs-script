#!/bin/sh

set -e
source ./env-setup.sh
mkdir -pv $LFS/root
cp ./chroot-init.sh $LFS/root

FROM=$(stat -c '%U' "$LFS")
chown --from $FROM -R root:root $LFS/{usr,lib,var,etc,bin,sbin}
case $(uname -m) in
  x86_64) chown --from $FROM -R root:root $LFS/lib64 ;;
esac
mkdir -pv $LFS/{dev,proc,sys,run}
mount -v --bind /dev $LFS/dev

mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run