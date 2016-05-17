#!/bin/bash

OPENVPN_USER=`head -n 1 openvpn_creds`
OPENVPN_PASS=`tail -n 1 openvpn_creds`

if [[ "$username" == "$OPENVPN_USER" && "$password" == "$OPENVPN_PASS" ]]; then
    exit 0
else
    exit 1
fi
