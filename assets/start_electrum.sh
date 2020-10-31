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

    read -p "Press ENTER to close terminal." answer
    exit 1
}

# ask user to input until we get expected reuslts
#   $1 : prompt; 
#   $2 : regex pattern
#   $3 : flag to lower case
function get_user_choice() {
    while true; do
        read -p "$1" choice
        if [[ $3 == true ]]; then
            choice=${choice,,} # tolower
        fi
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
        #                 EROAS ONE-TIME SETUP                      #
        #                                                           #
        #############################################################

Welcome! If you ever need to run one-time setup again, simply delete 
the config file and restart Electrum wallet.

The config file is at $CONFIG_FILE

EOF
}

function setup_fs_password() {
    cat << EOF

=======> Crypto filesystem password

EROAS uses a password-protected encrypted filesystem to store Electrum 
wallet data files.  You are strongly encouraged to change it to your 
own password.

EOF

    get_user_choice "Change crypto filesystem password? (Y/n) " "^(y|n|)$" true
    if [[ $choice == "n" ]]; then return; fi

    cat << EOF

Enter current password first and then set up a new one.  Unless you have 
changed it, initial password is 'eroas'. 
EOF

    while true; do
        echo
        cryptmount --change-password eroas_crypto_fs
        if [[ $? == 0 ]]; then break; fi
    done
}

function setup_network() {
    cat << EOF

=======> Networking setup

EROAS supports 3 networking modes:

    1. Use Tor to connect Electrum open servers (default)
    2. Connect to dedicated Electrum server directly
    3. Connect to dedicated Electrum server via SSH (advanced)

EOF

    get_user_choice "Which mode do you like? (1/2/3, default:1) " "^(1|2|3|)$"
    if [[ -z $choice ]]; then choice="1"; fi
    NETWORK_MODE=$choice

    if [[ $NETWORK_MODE == 1 ]]; then
        cat << EOF

=======> Allow outgoing HTTP/HTTPS

Allowing outgoing HTTP/HTTPS will shorten the initial network connection 
time whne you start Electrum. It also enables certain convenience features
such as fiat currency balance.  Disabling it gives better security.

EOF

        get_user_choice "Allow outgoing HTTP/HTTPS traffic? (Y/n) " "^(y|n|)$" true
        if [[ -z $choice ]]; then choice="y"; fi

        NETWORK_HTTP=$choice
    fi

    if [[ $NETWORK_MODE == 2 || $NETWORK_MODE == 3 ]]; then
        echo
        echo "=======> Electrum server info"
        echo

        get_user_choice "Server IP address (NO domain name)? " "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
        SERVER_IP=$choice

        get_user_choice "Server port (default:50002)? " "^([0-9]{2,5}|)$"
        if [[ -z $choice ]]; then 
            SERVER_PORT=50002 
        else 
            SERVER_PORT=$choice
        fi
    fi

    if [[ $NETWORK_MODE == 3 ]]; then
        echo
        echo "=======> SSH credential"
        echo

        get_user_choice "SSH port? (default:22) " "^([0-9]{2,5}|)$"
        if [[ -z $choice ]]; then choice=22; fi
        SSH_PORT=$choice

        get_user_choice "SSH user name? " "^[a-z][a-z0-9_-]{0,30}$" false
        SSH_USER=$choice

        cat << EOF

EROAS supports 3 ways to authenticate SSH user

    1. plain password 
    2. default config/key setup under ~/.ssh
    3. custom private key or certificate (.pem) file

EOF

        get_user_choice "Which SSH autentication method? (1/2/3) " "^(1|2|3)$"
        SSH_AUTH_METHOD=$choice

        if [[ $SSH_AUTH_METHOD == 1 ]]; then
            get_user_choice "Please enter SSH password? " "^.+$" false
            SSH_AUTH_DATA=$choice
        elif [[ $SSH_AUTH_METHOD == 3 ]]; then
            while true; do
                get_user_choice "Please input key/pem file path? " "^.*$" false
                SSH_AUTH_DATA=$(readlink -f $SSH_AUTH)
                if [[ -f $SSH_AUTH_DATA ]]; then break; fi
                echo "Key/pem file does not exist : $SSH_AUTH_DATA"
            done
        fi
    fi
}

function setup_save() {
    cat > $CONFIG_FILE << EOF
NETWORK_MODE=$NETWORK_MODE
NETWORK_HTTP=$NETWORK_HTTP
SERVER_IP=$SERVER_IP
SERVER_PORT=$SERVER_PORT
SSH_PORT=$SSH_PORT
SSH_USER=$SSH_USER
SSH_AUTH_METHOD=$SSH_AUTH_METHOD
SSH_AUTH_DATA=$SSH_AUTH_DATA
EOF
}

function setup_closing() {
    echo 
    echo "=======> One-time setup is almost done!"
    echo

    get_user_choice "Is this the first time you run setup? (Y/n) " "^(y|n|)$" true
    if [[ $choice != "n" && $NETWORK_MODE == 1 ]]; then
        echo
        echo "All set! Starting Electrum wallet ..."
        return
    elif [[ $choice != "n" ]]; then
        echo
        echo "Please reboot the system for networking to take effect."
        quitting
    fi

    get_user_choice "Did you change network settings this time? (y/n) " "^(y|n)$" true
    if [[ $choice == "y" ]]; then
        echo
        echo "Please reboot the system for networking to take effect."
        quitting
    else
        echo
        echo "All set! Starting Electrum wallet ..."
    fi
}

function setup_config() {
    setup_banner
    setup_fs_password
    setup_network
    setup_save
    setup_closing
}

# =============== main ==================

function setup_ssh_tunnel() {
    ret=$(netstat -tulpn 2>/dev/null | grep 50002)
    if [[ ! -z $ret ]]; then
        echo "SSH tunnel is already set up!"
        return
    fi

    if [[ $SSH_AUTH_METHOD == 1 ]]; then
        cmd="sshpass -p $SSH_AUTH_DATA ssh -fN -o 'StrictHostKeyChecking=no' -L 127.0.0.1:50002:localhost:$SERVER_PORT $SSH_USER@$SERVER_IP"
    elif [[ $SSH_AUTH_METHOD == 2 ]]; then
        cmd="ssh -fN -o 'StrictHostKeyChecking=no' -L 127.0.0.1:50002:localhost:$SERVER_PORT $SSH_USER@$SERVER_IP" 
    elif [[ $SSH_AUTH_METHOD == 3 ]]; then
        cmd="ssh -fN -i $SSH_AUTH_DATA -o 'StrictHostKeyChecking=no' -L 127.0.0.1:50002:localhost:$SERVER_PORT $SSH_USER@$SERVER_IP" 
    else 
        myerror "Unknown SSH auth method : $SSH_AUTH_METHOD"
    fi

    echo "Setting up SSH tunnel ... "
    $cmd
    if [[ $? != 0 ]]; then
        myerror "Failed to set up SSH tunnel : $cmd"
    fi
}


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
parse_config "$CONFIG_FILE" "NETWORK_MODE NETWORK_HTTP SERVER_IP SERVER_PORT SSH_PORT SSH_USER SSH_AUTH_METHOD SSH_AUTH_DATA"
if [[ $result != true ]]; then
    myerror "parsing config file failed"
fi

# mount crypto fs

# skip if crypto fs is already mounted
if [[ $(mount | grep eroas_crypto_fs) ]]; then
    echo "EROAS crypto filesystem is already mounted."
else
    # try auto-mount with default password
    exec 10<<<"eroas"
    cryptmount --passwd-fd 10 eroas_crypto_fs 2> /dev/null
    # otherwise we ask user to enter the password
    if [[ $? != 0 ]]; then
        echo "Mounting EROAS crypto filesystem ... enter your password below."
        while true; do
            cryptmount eroas_crypto_fs
            if [[ $? == 0 ]]; then break; fi
        done
    fi
fi

echo
echo "EROAS crypto filesystem is mounted. Starting Electrum ..."

# start electrum. Use tor mode for now.
if [[ $NETWORK_MODE == 1 ]]; then
    echo electrum -p 127.0.0.1:9050 
    nohup electrum -p 127.0.0.1:9050 > /dev/null 2>&1 &
elif [[ $NETWORK_MODE == 2 ]]; then
    echo electrum -1 -s $SERVER_IP:$SERVER_PORT:s 
    nohup electrum -1 -s $SERVER_IP:$SERVER_PORT:s > /dev/null 2>&1 &
elif [[ $NETWORK_MODE == 3 ]]; then
    setup_ssh_tunnel
    echo electrum -1 -s 127.0.0.1:50002:s 
    nohup electrum -1 -s 127.0.0.1:50002:s > /dev/null 2>&1 &
else
    myerror "Unknown networking mode : $NETWORK_MODE"
fi

# delayed quitting is necessary because electrum need time to get started
echo
quitting
