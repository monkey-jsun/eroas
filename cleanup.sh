#!/bin/bash

# safely remove chroot/ directory top working directory

echo "STOP!!! - This script will delete chroot/ and image/ directories "
echo "        - It makes env ready for a new ISO build"
echo
read -p "Press RETURN to continue ..." answer

set -x

sudo chroot chroot umount /proc > /dev/null 2>&1
sudo chroot chroot umount /sys > /dev/null 2>&1
sudo chroot chroot umount /dev/pts > /dev/null 2>&1

sudo umount chroot/dev > /dev/null 2>&1
sudo umount chroot/run > /dev/null 2>&1

sudo rm -rf chroot

rm -rf image/
