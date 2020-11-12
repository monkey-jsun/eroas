#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
#set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

CMD=(setup_host debootstrap run_chroot fixup build_iso)

VERSION="v1.1.1"
DATE=`TZ="UTC" date +"%y%m%d-%H%M%S"`

DEV=${DEV:-0}
if [[ $DEV != 0 ]]; then 
    echo "=====> eroas development build"
    VERSION=${VERSION}-dev
else
    echo "=====> EROAS production build"
fi

function help() {
    # if $1 is set, use $1 as headline message in help()
    if [ -z ${1+x} ]; then
        echo -e "This script builds EROAS (Electrum-Running-On-A-Stick)"
        echo -e
    else
        echo -e $1
        echo
    fi
    echo -e "Supported commands : ${CMD[*]}"
    echo -e
    echo -e "Syntax: $0 [start_cmd] [-] [end_cmd]"
    echo -e "\trun from start_cmd to end_end"
    echo -e "\tif start_cmd is omitted, start from first command"
    echo -e "\tif end_cmd is omitted, end with last command"
    echo -e "\tenter single cmd to run the specific command"
    echo -e "\tenter '-' as only argument to run all commands"
    echo -e
    exit 0
}

function find_index() {
    local ret;
    local i;
    for ((i=0; i<${#CMD[*]}; i++)); do
        if [ "${CMD[i]}" == "$1" ]; then
            index=$i;
            return;
        fi
    done
    help "Command not found : $1"
}

function chroot_enter_setup() {
    sudo mount --bind /dev chroot/dev
    sudo mount --bind /run chroot/run
    sudo chroot chroot mount none -t proc /proc
    sudo chroot chroot mount none -t sysfs /sys
    sudo chroot chroot mount none -t devpts /dev/pts
}

function chroot_exit_teardown() {
    sudo chroot chroot umount /proc
    sudo chroot chroot umount /sys
    sudo chroot chroot umount /dev/pts
    sudo umount chroot/dev
    sudo umount chroot/run
}

function check_host() {
    local os_ver;
    os_ver=`lsb_release -d | grep "Ubuntu 20.04"`
    if [[ $os_ver == "" ]]; then
        echo "WARNING : OS is not Ubuntu 20.04 and is untested"
    fi

    if [ $(id -u) -eq 0 ]; then
        echo "This script should not be run as 'root'"
        exit 1
    fi
}

function setup_host() {
    echo "=====> running setup_host ..."
    sudo apt update
    sudo apt install -y binutils debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools
    sudo mkdir -p chroot
}

function debootstrap() {
    echo "=====> running debootstrap ... will take a couple of minutes ..."
    sudo debootstrap  --arch=amd64 --variant=minbase focal chroot  http://us.archive.ubuntu.com/ubuntu/
}

function run_chroot() {
    echo "=====> running run_chroot ..."

    chroot_enter_setup

    sudo ln -f $SCRIPT_DIR/chroot_build.sh chroot/root/chroot_build.sh
    sudo cp -f /etc/apt/sources.list chroot/etc/apt/
    sudo chroot chroot /root/chroot_build.sh -
    sudo rm -f chroot/root/chroot_build.sh

    chroot_exit_teardown
}

function fixup() {
    echo "=====> running fixup ..."

    chroot_enter_setup

    # create "EroasExport" FAT32 instead "writable" partition
    # we have attached "home-rw" partition in ISO already for persistency
    sudo patch -p0 < assets/01-create-eroas-export-partition.patch


    # remove sudoers.d/casper; we still need to remove ubuntu
    # from sudo/adm group during runtime (eroas.service)
    # only do this for production build
    if [[ $DEV == 0 ]]; then
        sudo patch -p0 < assets/02-remove-ubuntu-sudoer.patch
    fi

    # make lightdm use xfce session as default.  Otherwise we will
    # gnome shell instead
    sudo patch -p0 < assets/03-lightdm-default-xfce.patch

    # remove xfce bottom panel.  Annonying. Most icons are broken anyway.
    sudo patch -p0 < assets/04-xfce-remove-bottom-panel.patch

    # enable cryptmount-setup to run in script, using fixed password
    sudo patch -p0 < assets/05-cryptmount-setup-run-in-script.patch

    # make NetworkManager/wifi settings persistent; perform eroas system setup
    sudo cp assets/eroas.service chroot/etc/systemd/system/
    sudo cp assets/eroas_system_setup.sh chroot/usr/local/sbin/
    sudo chroot chroot systemctl enable eroas

    # setup crypto mount
    sudo cp chroot/etc/cryptmount/cmtab chroot/etc/cryptmount/cmtab.bckp-setup
    sudo cp assets/cmtab chroot/etc/cryptmount/cmtab


    # make electrum an launcher icon on desktop
    sudo cp assets/electrum-logo-128px.png chroot/usr/local/share
    sudo cp assets/start_electrum.sh chroot/usr/local/bin
    sudo mkdir -p chroot/etc/skel/Desktop
    sudo cp assets/Electrum.desktop chroot/etc/skel/Desktop

    # change desktop background to our own
    sudo cp assets/eroas-desktop-wallpaper.png chroot/usr/share/backgrounds/xfce/xfce-stripes.png

    # lastly update initramfs, since we changed some casper scripts
    sudo chroot chroot update-initramfs -u

    chroot_exit_teardown
}

function build_iso() {
    echo "=====> running build_iso ..."

    rm -rf image
    mkdir -p image/{casper,isolinux,install}

    # copy kernel files
    sudo cp chroot/boot/vmlinuz-**-**-generic image/casper/vmlinuz
    sudo cp chroot/boot/initrd.img-**-**-generic image/casper/initrd

    # grub
    touch image/ubuntu
    cat <<EOF > image/isolinux/grub.cfg

search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=1

menuentry "Run EROAS (Electrum Running On A Stick)" {
   linux /casper/vmlinuz boot=casper persistent splash noprompt fsck.mode=skip ---
   initrd /casper/initrd
}

menuentry "Check disc for defects" {
   linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
   initrd /casper/initrd
}
EOF

# options
#   noprompt - don't ask to eject media on reboot/shutdown
#   fsck.mode=skip - skip initial media integrity checking
#   toram - copy RO data to ram first before execution so that we can remount
#       ro disk/partitions (?) and maybe run faster later
# original option
#   linux /casper/vmlinuz boot=casper nopersistent toram quiet splash ---

    # generate manifest
    sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest
    sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
    sudo sed -i '/ubiquity/d' image/casper/filesystem.manifest-desktop
    sudo sed -i '/casper/d' image/casper/filesystem.manifest-desktop
    sudo sed -i '/discover/d' image/casper/filesystem.manifest-desktop
    sudo sed -i '/laptop-detect/d' image/casper/filesystem.manifest-desktop
    sudo sed -i '/os-prober/d' image/casper/filesystem.manifest-desktop

    # compress rootfs
    sudo mksquashfs chroot image/casper/filesystem.squashfs
    printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

    # create diskdefines
    cat <<EOF > image/README.diskdefines
#define DISKNAME  Electrum Running On A Stick
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

    # create iso image
    pushd $SCRIPT_DIR/image
    grub-mkstandalone \
        --format=x86_64-efi \
        --output=isolinux/bootx64.efi \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=isolinux/grub.cfg"
    
    (
        cd isolinux && \
        dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
        sudo mkfs.vfat efiboot.img && \
        LC_CTYPE=C mmd -i efiboot.img efi efi/boot && \
        LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
    )

    (
        cd isolinux && \
        dd if=/dev/zero of=home-rw.img bs=1M count=256 && \
        mkfs.ext4 home-rw.img && \
        tune2fs -L home-rw home-rw.img 
    )

    grub-mkstandalone \
        --format=i386-pc \
        --output=isolinux/core.img \
        --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
        --modules="linux16 linux normal iso9660 biosdisk search" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=isolinux/grub.cfg"

    cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img

    sudo /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'bios.img' -e 'efiboot.img' > md5sum.txt)"

    sudo xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "EROAS_$VERSION" \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
        --grub2-boot-info \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
        -append_partition 2 0xef isolinux/efiboot.img \
        -append_partition 3 0x83 isolinux/home-rw.img \
        -output "../eroas-$VERSION-$DATE.iso" \
        -m "isolinux/efiboot.img" \
        -m "isolinux/bios.img" \
        -graft-points \
           "/EFI/efiboot.img=isolinux/efiboot.img" \
           "/boot/grub/bios.img=isolinux/bios.img" \
           "."

    popd
}

# =============   main  ================

# we always stay in $SCRIPT_DIR
cd $SCRIPT_DIR

check_host

# check number of args
if [[ $# == 0 || $# > 3 ]]; then help; fi

# loop through args
dash_flag=false
start_index=0
end_index=${#CMD[*]}
for ii in "$@";
do
    if [[ $ii == "-" ]]; then
        dash_flag=true
        continue
    fi
    find_index $ii
    if [[ $dash_flag == false ]]; then
        start_index=$index
    else
        end_index=$(($index+1))
    fi
done
if [[ $dash_flag == false ]]; then
    end_index=$(($start_index + 1))
fi

#loop through the commands
for ((ii=$start_index; ii<$end_index; ii++)); do
    ${CMD[ii]}
done

echo "$0 - Initial build is done!"

