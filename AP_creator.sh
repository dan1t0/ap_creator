#!/bin/bash

#Change it
if_out="eth0"
if_wifi="wlx14cc201b721e"


ip_address="192.168.10.1"
masq="255.255.255.0"
conf_file="ap.conf"
pass=$(cat $conf_file | grep wpa_passphrase | cut -d"=" -f2)
ssid=$(cat $conf_file | grep ^ssid | cut -d"=" -f2)


trap ctrl_c INT
function ctrl_c(){
    echo Killing processes..
    killall dnsmasq
    killall hostapd
}

echo -n "-> Seting IP Forwarding... "
sysctl -w net.ipv4.ip_forward=1 > /dev/null
echo "done"

echo -n "-> Configuring WiFi interface... "
ifconfig $if_wifi down
ifconfig $if_wifi up $ip_address netmask $masq
echo "done"

echo "-> Creating AP"
echo "  - SSID: $ssid "
echo "  - Password: $pass "
echo "  - AP source: $ip_address / $masq "

dnsmasq -C dnsmasq.conf -H dns_entries
ps aux | grep dnsmasq | grep -v grep > /dev/null
if [ $? -eq 0 ]
then
	echo "  - DHCP server: UP"
	echo "  - DNS server: UP"
else
	echo "  - DHCP server: none"
	echo "  - DNS server: none"
fi



echo -n "-> Enabling NAT... "
#Enable NAT
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
#iptables --table nat --append POSTROUTING --out-interface $if_out -j MASQUERADE
#iptables --append FORWARD --in-interface $if_wifi -j ACCEPT
echo "done"

iptables -t nat -A POSTROUTING -o $if_out -j MASQUERADE
iptables -A FORWARD -i $if_wifi -j ACCEPT



#rfkill list
echo -n "-> Unlocking wifi iface... " #'thanks' ubuntu
nmcli radio wifi off
rfkill unblock wlan
echo "done"

echo""
echo ""
hostapd $conf_file
echo ""
echo ""

echo -n "-> Unseting IP Forwarding... " 
sysctl -w net.ipv4.ip_forward=0 > /dev/null
echo "done"

echo -n "-> Disabling wlan interface... "
ifconfig $if_wifi down
echo "done"

echo -n "-> Flushing iptables ... "
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo "done"
echo ""

echo "Finish!"

