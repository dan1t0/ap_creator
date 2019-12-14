#!/bin/bash

#Change it
if_out="eno1"
if_wifi="wlp3s0"


ip_address="192.168.10.1"
masq="255.255.255.0"
conf_file="ap.conf"
pass=$(cat $conf_file | grep wpa_passphrase | cut -d"=" -f2)
ssid=$(cat $conf_file | grep ssid | cut -d"=" -f2)

echo "CREATE AP"
echo " - SSID: $ssid "
echo " - Password: $pass "
echo " - AP source: $ip_address / $masq "
echo " - DHCP server: none"
echo " - DNS server: none"
echo ""
echo ""

echo -n "----> set ip_forward=1  ... "
sysctl -w net.ipv4.ip_forward=1 > /dev/null
echo "done"

echo -n "----> configure wlan interface ... "
ifconfig $if_wifi down
ifconfig $if_wifi up $ip_address netmask $masq
echo "done"

echo -n "----> Enable NAT... "
#Enable NAT
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables --table nat --append POSTROUTING --out-interface $if_out -j MASQUERADE
iptables --append FORWARD --in-interface $if_wifi -j ACCEPT
echo "done"

#rfkill list
echo -n "----> unlock wifi iface ... " #'thanks' ubuntu
rfkill unblock wlan
nmcli radio wifi off
echo "done"

echo""
echo ""
hostapd $conf_file
echo ""
echo ""

echo -n "----> set ip_forward=0  ... " 
sysctl -w net.ipv4.ip_forward=0 > /dev/null
echo "done"

echo -n "----> disable wlan interface ... "
ifconfig $if_wifi down
echo "done"

echo -n "----> flushing iptables ... "
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo "done"

echo "finish!"
echo ""

