#!/bin/bash

EXPECTED_USER="foo"
EXPECTED_PASSWORD="bar"

if [[ "$username" == "$EXPECTED_USER" && "$password" == "$EXPECTED_PASSWORD" ]]; then
    exit 0
else
    exit 1
fi
