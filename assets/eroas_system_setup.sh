#!/bin/bash

# create wifi persistent directory if not existing
if [ ! -d /home/casper ]; then
    echo "first-time running; create /home/casper directory ..."
    mkdir -p /home/casper/etc/NetworkManager/system-connections
    chmod o-rx /home/casper
fi

# mount over the RO part and restart NetworkManager
echo "bind-mount /etc/NetworkManager/system-connections ..."
mount --bind /home/casper/etc/NetworkManager/system-connections /etc/NetworkManager/system-connections
systemctl restart NetworkManager

# remove ubuntu from sudo/adm groups
sed -i "s#adm:x:4:ubuntu#adm:x:4:#" /etc/group
sed -i "s#sudo:x:27:ubuntu#sudo:x:27:#" /etc/group

# check crypto fs
if [[ -f /home/ubuntu/.config/eroas/eroas_crypto_fs.bin ]]; then
    exit 0
fi

# prepare to create crypto fs

# use empty cmtab so that we can add a new one for the first time running
# on later bootup, we should revert back to existing cmtab which matches
# our created result, due to ro attribute of system partition
cp -f /etc/cryptmount/cmtab.bckp-setup /etc/cryptmount/cmtab

# remove any artifacts from failed build.  There should not be any.
# we are just paranoid
rm -f /home/casper/eroas_crypto_fs.key
rm -rf /home/ubuntu/.electrum

# create crypto fs
echo "first time running; create crypto fs for electrum wallet ..."
cryptmount-setup << EOF
eroas_crypto_fs
ubuntu
/home/ubuntu/.electrum
128
/home/ubuntu/.config/eroas/eroas_crypto_fs.bin
/home/casper/eroas_crypto_fs.key
yes
EOF

echo "All done!"

exit 0
