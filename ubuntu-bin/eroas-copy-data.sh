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
    cat << EOF
Usage : $0 <src usb dev> <dest usb dev>

    copy EROAS data from one EROAS USB to another for backup/restore
    Specifically we copy forcefully
        everything on EroasExport partition 
        encrypted fs that contains the wallet
        /home/casper/ that contains rw system files (e.g., wifi pass, fs key)
        eroas config file
        /home/ubuntu/bin

    Source and destination usb must have standard partition layout
    Destination USB must have booted up at least once to have standard layout"

Example : $0 sdb sdc"

EOF
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

# check to dst contains newer files than src
function check_newer() {
    local src=$1
    local dst=$2

    local tmp=$(rsync --dry-run -a -i --update $2 $1 | grep "^>f" | grep -v "^>f+++++")
    if [[ $tmp != "" ]]; then
        echo
        echo "WARNING : destination folder has newer files : $2"
        echo "$tmp"
        echo
    fi
}

function do_copying() {
    local dry_run=$1

    # copy export partition
    mount /dev/${src_disk}3 /mnt/tmp1
    mount /dev/${dst_disk}3 /mnt/tmp2
    
    echo copy EroasExport partition data ....
    rsync $dry_run -a -i --delete /mnt/tmp1/ /mnt/tmp2/
    
    umount /mnt/tmp1
    umount /mnt/tmp2
    
    # copy home-rw partitoin
    echo
    echo copy home-rw partition data ....
    mount /dev/${src_disk}2 /mnt/tmp1
    mount /dev/${dst_disk}2 /mnt/tmp2
    
    list="casper/ eroas_crypto_fs.bin ubuntu/.eroas_config ubuntu/bin/"
    for i in $list; do
        rsync $dry_run -a -i --delete /mnt/tmp1/$i /mnt/tmp2/$i
    done
    
    umount /mnt/tmp1
    umount /mnt/tmp2
}

# check # of args
if [[ $# != 2 ]]; then
    help
fi

src_disk=$1
dst_disk=$2

check_eroas_usb $src_disk
check_eroas_usb $dst_disk

# umount partitions if already mounted
umount /dev/${src_disk}2 || true
umount /dev/${dst_disk}2 || true
umount /dev/${src_disk}3 || true
umount /dev/${dst_disk}3 || true

# check newer or to-be-deleted
mkdir -p /mnt/tmp1
mkdir -p /mnt/tmp2

umount /mnt/tmp1 || true
umount /mnt/tmp2 || true

echo "check for newer or to-be-deleted files on destination disk ..."

mount /dev/${src_disk}3 /mnt/tmp1
mount /dev/${dst_disk}3 /mnt/tmp2

# note ending '/' is meaningful here!!!
check_newer /mnt/tmp1/ /mnt/tmp2/

umount /mnt/tmp1
umount /mnt/tmp2

# check for newer files in dst home folder
mount /dev/${src_disk}2 /mnt/tmp1
mount /dev/${dst_disk}2 /mnt/tmp2

list="casper/ eroas_crypto_fs.bin ubuntu/.eroas_config ubuntu/bin/"
for i in $list; do
    check_newer /mnt/tmp1/$i /mnt/tmp2/$i
done

umount /mnt/tmp1
umount /mnt/tmp2

echo
read -p "Please review and enter YES to proceed with dry-run : " answer
if [[ $answer != "YES" ]]; then
    exit 0
fi

do_copying "--dry-run"

echo
read -p "Please review changes above and enter YES to commit : " answer
if [[ $answer != "YES" ]]; then
    exit 0
fi

do_copying ""

echo "Done!"
