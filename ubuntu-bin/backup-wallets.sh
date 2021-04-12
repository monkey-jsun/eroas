#!/bin/bash

cd ~/.electrum
tar cz wallets | openssl enc -aes-256-cbc -e > ./electrum_wallets.tgz.enc

