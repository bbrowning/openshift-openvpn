#!/bin/bash

if [ "$DEBUG" == "true" ]; then
    set -x
fi

set -e

# echo "common_name: $common_name"
# echo "ifconfig_pool_local_ip: $ifconfig_pool_local_ip"
# echo "ifconfig_pool_netmask: $ifconfig_pool_netmask"
# echo "ifconfig_pool_remote_ip: $ifconfig_pool_remote_ip"
# echo "script_type: $script_type"
# echo "trusted_ip: $trusted_ip"
# echo "trusted_port: $trusted_port"

IPTABLES=/sbin/iptables
$IPTABLES -t nat -F PREROUTING
# $IPTABLES -t nat -F OUTPUT

if [[ "$script_type" == "client-connect" ]]; then
    # Redirect all incoming non-OpenVPN connections to the VPN client
    $IPTABLES -t nat -A PREROUTING -i eth0 -p tcp ! --dport 1194 -j DNAT --to-destination ${ifconfig_pool_remote_ip}
    # $IPTABLES -t nat -A OUTPUT -m addrtype --src-type LOCAL -p tcp ! --dport 1194 -j DNAT --to-destination ${ifconfig_pool_remote_ip}
fi
