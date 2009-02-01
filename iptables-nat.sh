#!/bin/sh
#
# usage (e.g.): sudo sh iptables-nat.sh [public interface] [private interface]
#
# Sets up iptables on Linux 2.6 to run a NAT for all machines on the
# private interface via the IP bound to the public interface. You should
# manually configure a private RFC1918 network for the machines on the
# private interface.
#
# Derived from the Linux IP masquerade HOWTO.

public=${1:-ath0}
private=${2:-eth0}

# permit forwarding connections that have to do with the NAT
iptables -A FORWARD -i $private -o $public -j ACCEPT
iptables -A FORWARD -i $public -o $private -m state --state ESTABLISHED,RELATED -j ACCEPT

# drop other connections, else the remaining commands will NAT public requests
# routed to this machine
iptables -P FORWARD DROP

# enable NAT
iptables -t nat -A POSTROUTING -o $public -j MASQUERADE

# this is usually not on by default
echo 1 > /proc/sys/net/ipv4/ip_forward
