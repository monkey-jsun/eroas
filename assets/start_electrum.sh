#!/bin/bash

# TODO:
#   convert server name to IP (we use IP only)
#   trim input
#   allow multiple ways for ssh
#       private key 
#       pem file
#       password (is this possible for tunneling?)

set -e
set -o pipefail
set -u
#set -x

# for now we start in Tor mode only
nohup electrum -p 127.0.0.1:9050 > /dev/null 2>&1 &
exit 0

EROAS_CONFIG=/home/ubuntu/.eroas_config

function get_user_choice() {
    echo -e "\n$1\n"
    while true; do
        read -p "Please input your choice (default:$2) : " choice
        if [[ $choice == '' ]]; then choice=$2; fi
        if [[ $choice > $3 || $choice < 1 ]]; then
            echo -e "Invalid choice.  Please try again."
            continue;
        fi
        break;
    done
}

function build_config_input() {
    msg="
EROAS supports 3 networking modes:

  1. Use Tor to connect to open Electrum network servers (default).
  2. Connect to designated Electrum server directly
  3. Connect to designated Electrum server via SSH tunnel (advanced)
"
	get_user_choice "$msg" 1 3

	if [[ $choice == 1 ]]; then
        ELECTRUM_SERVER=
        ELECTRUM_PORT=
        SSH_SERVER=
        SSH_PORT=
        SSH_USER=
        SSH_PASSWD=
	elif [[ $choice == 2 ]]; then
		read -p "Input electrum server name or IP address : " ELECTRUM_SERVER
		read -p "Input electrum server port (default:50002) : " ELECTRUM_PORT
        SSH_SERVER=
        SSH_PORT=
        SSH_USER=
        SSH_PASSWD=
    elif [[ $choice == 3 ]]; then
        ELECTRUM_SERVER=localhost
		read -p "Input ssh server name or IP address : " SSH_SERVER
		read -p "Input ssh server port (default:22) : " SSH_PORT
		read -p "Input ssh user login : " SSH_USER
		read -p "Input ssh user password : " SSH_PASSWD
		read -p "Input electrum server port (default:50002) : " ELECTRUM_PORT
    fi

    if [ -z $ELECTRUM_PORT ]; then ELECTRUM_PORT=50002; fi
    if [ -z $SSH_PORT ]; then SSH_PORT=22; fi

}

function build_config() {
    while true; do
        build_config_input
        if [[ $choice == 2 && -z ELECTRUM_SERVER ]]; then
            echo "Electrum server name cannot be empty"
            continue;
        fi
        if [[ $choice == 3 ]]; then
            if [[ -z $SSH_SERVER || -z $SSH_USER || -z $SSH_PASSWD ]]; then
                echo SSH server/user/passwd cannot be empty
                continue
            fi
        fi
        break
    done

    cat << EOF > $EROAS_CONFIG
ELECTRUM_SERVER=$ELECTRUM_SERVER
ELECTRUM_PORT=$ELECTRUM_PORT
SSH_SERVER=$SSH_SERVER
SSH_PORT=$SSH_PORT
SSH_USER=$SSH_USER
SSH_PASSWD=$SSH_PASSWD
EOF
}

if [ ! -f $EROAS_CONFIG ]; then
    build_config
fi

. $EROAS_CONFIG

if [ -z $ELECTRUM_SERVER ]; then
    # use Tor to connect to open network
    nohup electrum -p sock5:localhost:9050 > /dev/null 2>&1 &
elif [ -z $SSH_SERVER ]; then
    # direct connect to designated server
    nohup electrum -1 -s $ELECTRUM_SERVER:$ELECTRUM_PORT:s > /dev/null 2>&1 &
elif [[ $ELECTRUM_SERVER == "localhost" ]]; then
    # SSH tunneling
    nohup electrum -1 -s localhost:$ELECTRUM_PORT:s > /dev/null 2>&1 &
else
    echo "ERROR: SSH_SERVER($SSH_SERVER) is set but ELECTRUM_SERVER($ELECTRUM_SERVER) is not localhost"
    echo "bail out ..."
    sleep 5
fi

