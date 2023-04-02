#!/bin/bash

set -u                  # treat unset variable as error
#set -x

sudo mount --rbind /dev chroot/dev
sudo mount --make-rslave chroot/dev
sudo mount --bind /run chroot/run
sudo mount --bind /proc chroot/proc
sudo mount --bind /sys chroot/sys

sudo ln -f chroot_build.sh chroot/root/chroot_build.sh

sudo chroot chroot 

sudo rm -f chroot/root/chroot_build.sh

sudo umount chroot/sys
sudo umount chroot/proc
sudo umount chroot/run
sudo umount -R chroot/dev
