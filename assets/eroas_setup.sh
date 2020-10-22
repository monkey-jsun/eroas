#!/bin/bash

# create wifi persistent directory if not existing
if [ ! -d /home/casper ]; then
    mkdir -p /home/casper/etc/NetworkManager/system-connections
fi

# mount over the RO part and restart NetworkManager
mount --bind /home/casper/etc/NetworkManager/system-connections /etc/NetworkManager/system-connections
systemctl restart NetworkManager

exit 0
