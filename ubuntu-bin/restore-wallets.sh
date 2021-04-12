#!/bin/bash

cd ~/.electrum
openssl enc -aes-256-cbc -d -in ./electrum_wallets.tgz.enc | tar xz
