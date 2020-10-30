#!/bin/bash

#   support #-started comment line (no # in the middle)
#   stripping white spaces at beginning and end and around "="
#   don't support " " for quoting string
#
# $1 - file name ("config.tx")
# $2 - a list of expected key words ("KEY1 KEY2 KEY3")
function parse_config() {
    echo "parsing config file $1 ..."
    result=true
    while read -r line
    do
        if [[ ! $line =~ .+=.* ]]; then
            echo "illegal line : $line"
            result=false
            break
        fi
        if [[ $line =~ ^#.* ]]; then
            echo "comment line; skipping ..."
            continue;
        fi
        key=$(echo $line | sed -e "s#=.*\$##" | xargs)
        value=$(echo $line | sed -e "s#^[^=]*=##" | xargs)
        if [[ ! $key =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
            echo "illegal key : $key"
            result=false
            break
        fi
        if [[ ! $2 =~ (^|[[:space:]])"$key"($|[[:space:]]) ]]; then
            echo "unexpected key, skipping : $key"
            continue
        fi
        printf -v "${key}" '%s' "${value}"
    done < "$1"
}

# ======== wifi persistency ================

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

# ======== remove sudo ================

# remove ubuntu from sudo/adm groups
sed -i "s#adm:x:4:ubuntu#adm:x:4:#" /etc/group
sed -i "s#sudo:x:27:ubuntu#sudo:x:27:#" /etc/group

# ======== setup firewall ================

# first remove existing rules, starting from #2
while true; do
    ufw --force delete 2
    if [[ $? != 0 ]]; then break; fi
done

# parse config file
CONFIG_FILE=/home/ubuntu/.eroas_config
if [[ -f $CONFIG_FILE ]];then
    parse_config "$CONFIG_FILE" "NETWORK_MODE NETWORK_HTTP SERVER_IP SERVER_PORT SSH_PORT"
    if [[ $result != true ]]; then
        NETWORK_MODE=0      # error case
    fi
else
    #default to Tor with HTTP 
    NETWORK_MODE=1
    NETWORK_HTTP=y
fi

if [[ $NETWORK_MODE == 1 ]]; then
    ufw allow out 9001
    if [[ $NETWORK_HTTP == "y" ]]; then
        ufw allow out 80
        ufw allow out 443
    fi
elif [[ $NETWORK_MODE == 2 ]]; then
    ufw allow out to "$SERVER_IP" port "$SERVER_PORT"
elif [[ $NETWORK_MODE == 3 ]]; then
    ufw allow out to "$SERVER_IP" port "$SSH_PORT"
fi
ufw reload

# ======== create crypto fs ================
    
# check crypto fs
if [[ -f /home/eroas_crypto_fs.bin ]]; then
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
/home/eroas_crypto_fs.bin
/home/casper/eroas_crypto_fs.key
yes
EOF

echo "All done!"

exit 0
