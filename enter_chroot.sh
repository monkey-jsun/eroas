#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
#set -x

sudo mount --bind /dev chroot/dev
sudo mount --bind /run chroot/run

sudo ln -f chroot_build.sh chroot/root/chroot_build.sh

sudo chroot chroot mount none -t proc /proc
sudo chroot chroot mount none -t sysfs /sys
sudo chroot chroot mount none -t devpts /dev/pts

sudo chroot chroot 

sudo chroot chroot umount /proc
sudo chroot chroot umount /sys
sudo chroot chroot umount /dev/pts

sudo rm -f chroot/root/chroot_build.sh

sleep 2

sudo umount chroot/dev
sudo umount chroot/run

