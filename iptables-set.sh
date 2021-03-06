#!/bin/bash
set -e

ip rule add fwmark $TPROXY_MARK table $TABLE
ip route add local default dev $NETWORK_INTERFACE table $TABLE

# packets will not go through tproxy if the tcp has already connected
iptables -t mangle -N DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark $TPROXY_MARK
iptables -t mangle -A DIVERT -j ACCEPT
iptables -t mangle -I PREROUTING -p tcp -m socket -j DIVERT

iptables -t mangle -N V2RAY
iptables -t mangle -A V2RAY -j RETURN -m mark --mark $SO_MARK
iptables -t mangle -A V2RAY -p udp --dport 53 $DNS_OPTIONS
iptables -t mangle -A V2RAY -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A V2RAY -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A V2RAY -p udp -j TPROXY --on-port $PORT --tproxy-mark $TPROXY_MARK
iptables -t mangle -A V2RAY -p tcp -j TPROXY --on-port $PORT --tproxy-mark $TPROXY_MARK
iptables -t mangle -A PREROUTING -j V2RAY
echo 1 > /proc/sys/net/ipv4/ip_forward

if [[ -z "$ONLY_ROUTE" ]]; then
iptables -t mangle -N V2RAY_MASK
iptables -t mangle -A V2RAY_MASK -j RETURN -m mark --mark $SO_MARK
iptables -t mangle -A V2RAY_MASK -p udp --dport 53 $MASK_DNS_OPTIONS
iptables -t mangle -A V2RAY_MASK -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A V2RAY_MASK -p udp -j MARK --set-mark $TPROXY_MARK
iptables -t mangle -A V2RAY_MASK -p tcp -j MARK --set-mark $TPROXY_MARK
iptables -t mangle -A OUTPUT -j V2RAY_MASK
fi
