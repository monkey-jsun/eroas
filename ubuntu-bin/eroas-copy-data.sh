#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
#set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [ $(id -u) -ne 0 ]; then
  echo "This script must be run as 'root'"
  exit 1
fi

function help() {
    echo -e "Usage : \n\t$0 <src usb dev> <dest usb dev>"
    echo
    echo -e "\tCopy data from one EROAS USB to another (usually for upgrading)"
    echo -e "\tDestination usb must have booted up at least once"
    echo
    echo -e "Example : \n\t$0 sdb sdc"
    echo
    exit 1
}

function myerror() {
    echo -e "ERROR : $1"
    echo
    echo -e "QUITING ...."
    exit 1
}

# check to see if disk is eroas disk; exit if not
function check_eroas_usb() {
    local disk=$1
    local line=$(lsblk -o NAME,LABEL /dev/$disk | grep ${disk}1)
    if [[ ! ${line} =~ .*EROAS.* ]]; then
        myerror "/dev/${disk}1 does not contain EROAS label : $line"
    fi
    local line=$(lsblk -o NAME,LABEL /dev/$disk | grep ${disk}2)
    if [[ ! ${line} =~ .*home-rw.* ]]; then
        myerror "/dev/${disk}2 does not contain home-rw label : $line"
    fi
    local line=$(lsblk -o NAME,LABEL /dev/$disk | grep ${disk}3)
    if [[ ! ${line} =~ .*EroasExport.* ]]; then
        myerror "/dev/${disk}3 does not contain EroasExport label : $line"
    fi
}

# check # of args
if [[ $# != 2 ]]; then
    help
fi

src_disk=$1
dst_disk=$2

check_eroas_usb $src_disk
check_eroas_usb $dst_disk

mkdir -p /mnt/tmp1
mkdir -p /mnt/tmp2

umount /mnt/tmp1 || true
umount /mnt/tmp2 || true

# we insist export partition should be empty
mount /dev/${dst_disk}3 /mnt/tmp2
if [[ "$(ls -A /mnt/tmp2)" ]]; then
    umount /mnt/tmp2
    myerror "destination disk export partition is not empty"
fi

# copy export partition
echo copy EroasExport partition data ....
mount /dev/${src_disk}3 /mnt/tmp1
cp -a /mnt/tmp1/* /mnt/tmp2/

umount /mnt/tmp1
umount /mnt/tmp2

# copy home-rw partitoin
echo copy home-rw partition data ....
mount /dev/${src_disk}2 /mnt/tmp1
mount /dev/${dst_disk}2 /mnt/tmp2

list="casper eroas_crypto_fs.bin ubuntu/.eroas_config ubuntu/bin"
pushd /mnt/tmp1
for i in $list; do
    cp -a --parents $i /mnt/tmp2/
done
popd

umount /mnt/tmp1
umount /mnt/tmp2

echo "Done!"
