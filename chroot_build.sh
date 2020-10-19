#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
#set -x

ELECTRUM_VERSION="4.0.4"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CHROOT_DIR=$SCRIPT_DIR/chroot

CMD=(setup_host install_pkg finish_up)

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

function check_host() {
    if [ $(id -u) -ne 0 ]; then
        echo "This script should be run as 'root'"
        exit 1
    fi

    export HOME=/root
    export LC_ALL=C
}

function setup_host() {
    echo "=====> running setup_host ..."
    mount none -t proc /proc
    mount none -t sysfs /sys
    mount none -t devpts /dev/pts

    echo "EROAS" > /etc/hostname

    cat <<EOF > /etc/apt/sources.list
deb http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse

deb http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse

deb http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
EOF

    # we need to install systemd first, to configure machine id
    apt-get update
    apt-get install -y libterm-readline-gnu-perl systemd-sysv

    #configure machine id
    dbus-uuidgen > /etc/machine-id
    ln -fs /etc/machine-id /var/lib/dbus/machine-id

    # don't understand why, but multiple sources indicate this
    dpkg-divert --local --rename --add /sbin/initctl
    ln -s /bin/true /sbin/initctl
}

function install_wallet() {
    echo "=====> running install_wallet ..."
    apt-get install -y tor
    apt-get install -y cryptsetup

    cd $HOME
    apt-get install -y python3-pyqt5 libsecp256k1-0 python3-cryptography python3-setuptools python3-pip
    pip3 install https://download.electrum.org/$ELECTRUM_VERSION/Electrum-$ELECTRUM_VERSION.tar.gz

    # setup a basic firewall for now.
    # I should not need the last "deny out 50002" rule. But otherwise
    # first time up the outgoing traffic to 50002 still happens.
    ufw default deny incoming
    ufw default deny outgoing
    ufw allow out 22
    ufw allow out 53
    ufw allow out 80
    ufw allow out 443
    ufw allow out 9001
    ufw deny out 50002
    ufw enable
}

function install_pkg() {
    install_pkg_simple
}

function install_pkg_simple() {
    echo "=====> running install_pkg ... will take a long time ..."
    apt-get -y upgrade

    # install live linux packages
    apt-get install -y ubuntu-standard casper lupin-casper laptop-detect os-prober linux-generic

    # install networking packages
    apt-get install -y \
        network-manager \
        resolvconf \
        net-tools \
        wireless-tools \
        wpagui \
        locales

    # install graphics and desktop
    apt-get install -y xfce4
    
    # install some utils
    apt-get install -y vim less curl apt-transport-https

    # disable cups by default (TODO: not working??)
    systemctl disable cups

    # install electrum wallet and related pkgs
    install_wallet

    # remove unneeded packages
    apt-get autoremove -y

    # configure pkgs
    dpkg-reconfigure locales
    dpkg-reconfigure resolvconf

    # network manager
    cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq

[ifupdown]
managed=false
EOF
    dpkg-reconfigure network-manager

    # strange, without apt-get clean, screen is dark, why??
    apt-get clean -y
}

function install_pkg_full() {
    echo "=====> running install_pkg ... will take a long time ..."
    apt-get -y upgrade

    # install live linux packages
    apt-get install -y \
    ubuntu-standard \
    casper \
    lupin-casper \
    discover \
    laptop-detect \
    os-prober \
    network-manager \
    resolvconf \
    net-tools \
    wireless-tools \
    wpagui \
    locales \
    linux-generic

    # skip ubiquity
    apt-get install -y \
   ubiquity \
   ubiquity-casper \
   ubiquity-frontend-gtk \
   ubiquity-slideshow-ubuntu \
   ubiquity-ubuntu-artwork

    # install graphics and desktop
    apt-get install -y \
    plymouth-theme-ubuntu-logo \
    ubuntu-gnome-desktop \
    ubuntu-gnome-wallpapers

    # useful tools
    apt-get install -y \
    clamav-daemon \
    terminator \
    apt-transport-https \
    curl \
    vim \
    nano \
    less

    # purge
    apt-get purge -y \
    transmission-gtk \
    transmission-common \
    gnome-mahjongg \
    gnome-mines \
    gnome-sudoku \
    aisleriot \
    hitori

    # remove unused and clean up apt cache
    apt-get autoremove -y

    # final touch
    dpkg-reconfigure locales
    dpkg-reconfigure resolvconf

    # network manager
    cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq

[ifupdown]
managed=false
EOF
    dpkg-reconfigure network-manager

    apt-get clean -y
}

function finish_up() { 
    echo "=====> finish_up"

    # truncate machine id (why??)
    truncate -s 0 /etc/machine-id

    # remove diversion (why??)
    rm /sbin/initctl
    dpkg-divert --rename --remove /sbin/initctl

    rm -rf /tmp/* ~/.bash_history

    umount /proc
    umount /sys
    umount /dev/pts
}

# =============   main  ================

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

# loop through the commands
for ((ii=$start_index; ii<$end_index; ii++)); do
    ${CMD[ii]}
done

echo "$0 - Initial build is done!"

