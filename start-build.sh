#!/bin/bash
set -e
source ./env-setup.sh
./setup-dir.sh
./setup-cross-compiler.sh
./setup-base-tools.sh
sudo ./prepare-chroot.sh