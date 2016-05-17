#!/bin/bash

if [[ "$username" == "$OPENVPN_USER" && "$password" == "$OPENVPN_PASS" ]]; then
    exit 0
else
    exit 1
fi
