#!/bin/bash

CONFIG_FILE=/home/ubuntu/.eroas_config

function quitting() {
    for (( count=5; count > 0; count-=1 )); do
        echo -n -e "\rClosing in $count seconds ...."
        sleep 1
    done
    echo
    echo
    exit 1
}

function myerror() {
    echo -e "ERROR : $1"
    echo
    quitting
}

# ask user to input until we get expected reuslts
#   $1 : prompt; 
#   $2 : regex pattern
function get_user_choice() {
    while true; do
        read -p "$1" choice
        choice=${choice,,} # tolower
        if [[ $choice =~ $2 ]]; then return; fi
        echo -e "\nUnexpected input.  Please try again.\n"
    done
}

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


# =============== setup ==================
function setup_banner() {
    cat << EOF

        #############################################################
        #                                                           #
        #             EROAS ONE-TIME CONFIGURATION                  #
        #                                                           #
        #############################################################

Welcome to EROAS one-time configuration. If you need to reconfigure EROAS, 
please delete the config file and reboot the system.

Config file is at $CONFIG_FILE

EOF
}

function setup_fs_password() {
    cat << EOF

=======> Crypto filesystem password

EROAS uses a password-protected encrypted filesystem to store Electrum 
wallet data files. You are strongly encouraged to customize the password, 
especially if you are using a standard USB drive without fingerprint or
keypad protection.

EOF

    get_user_choice "Customize filesystem password? (Y/n) " "^(y|n|)$"
    if [[ -z $choice ]]; then choice="y"; fi

    if [[ $choice == "n" ]]; then
        CRYPTO_FS_PASSWORD=standard
        return
    fi

    # change password
    echo
    echo "Enter 'eroas' below (default password), and then set up your new one"
    echo
    while true; do
        cryptmount --change-password eroas_crypto_fs
        if [[ $? == 0 ]]; then break; fi
    done
    CRYPTO_FS_PASSWORD=custom
}

function setup_save() {
    echo "CRYPTO_FS_PASSWORD=$CRYPTO_FS_PASSWORD" > $CONFIG_FILE
}

function setup_config() {
    setup_banner
    setup_fs_password

    setup_save

    echo 
    echo "=======> Configuration done!"
    echo
}

# =============== main ==================

# be paranoid, check crypt_fs readiness
while [[ ! -f /home/eroas_crypto_fs.bin ]]; do
    echo "Strange - waiting for crypto fs being ready ..."
    sleep 2
done

# check for config file
if [[ ! -f $CONFIG_FILE ]]; then
    setup_config
fi

# parse config file
parse_config "$CONFIG_FILE" "CRYPTO_FS_PASSWORD"
if [[ $result != true ]]; then
    myerror "parsing config file failed"
fi

# mount crypto fs

# skip if crypto fs is already mounted
if [[ $(mount | grep eroas_crypto_fs) ]]; then
    echo "EROAS crypto filesystem is already mounted."
elif [[ $CRYPTO_FS_PASSWORD == "custom" ]]; then
    echo "Mounting EROAS crypto filesystem ... enter your password below."
    while true; do
        cryptmount eroas_crypto_fs
        if [[ $? == 0 ]]; then break; fi
    done
elif [[ $CRYPTO_FS_PASSWORD == "standard" ]]; then
    echo "Mounting EROAS crypto filesystem with standard password ..."
    exec 10<<<"eroas"
    cryptmount --passwd-fd 10 eroas_crypto_fs 
else
    myerror "Unexpected value for CRYPTO_FS_PASSWORD : $CRYPTO_FS_PASSWORD"
fi

echo
echo "EROAS crypto filesystem is mounted. You may now start using Electrum wallet."
echo

quitting
