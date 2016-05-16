#!/bin/bash

if [ "$DEBUG" == "true" ]; then
    set -x
fi

set -e

# echo "dev: $dev"
# echo "ifconfig_broadcast: $ifconfig_broadcast"
# echo "ifconfig_local: $ifconfig_local"
# echo "ifconfig_remote: $ifconfig_remote"
# echo "ifconfig_netmask: $ifconfig_netmask"
# echo "link_mtu: $link_mtu"
# echo "route_net_gateway: $route_net_gateway"
# echo "route_vpn_gateway: $route_vpn_gateway"
# echo "script_context: $script_context"
# echo "script_type: $script_type"
# echo "tun_mtu: $tun_mtu"

IPTABLES=/sbin/iptables
$IPTABLES -t nat -F POSTROUTING

if [[ "$script_type" == "up" ]]; then
    # NAT traffic coming from VPN clients
    $IPTABLES -t nat -A POSTROUTING -s ${ifconfig_local}/${ifconfig_netmask} -o eth0 -j MASQUERADE

    # NAT traffic going to the VPN clients
    $IPTABLES -t nat -A POSTROUTING -d ${ifconfig_local}/${ifconfig_netmask} -o ${dev} -j MASQUERADE
fi
