#!/bin/bash

# create wifi persistent directory if not existing
if [ ! -d /home/casper ]; then
    mkdir -p /home/casper/etc/NetworkManager/system-connections
    chmod o-rx /home/casper
fi

# mount over the RO part and restart NetworkManager
mount --bind /home/casper/etc/NetworkManager/system-connections /etc/NetworkManager/system-connections
systemctl restart NetworkManager

# remove ubuntu from sudo/adm groups
sed -i "s#adm:x:4:ubuntu#adm:x:4:#" /etc/group
sed -i "s#sudo:x:27:ubuntu#sudo:x:27:#" /etc/group

exit 0
