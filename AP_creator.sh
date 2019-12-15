#!/bin/bash

#Change if needed
if_out="eth0"
if_wifi="wlx10feed1d7066"
ip_address="192.168.10.1"
ip_first=`echo ${ip_address} | cut -d"." -f1,2,3`
masq="255.255.255.0"
conf_file="ap.conf"
ssid="Danito"
pass="qwerty1234"


#if AP interface is set as parameter
if [ -n "$1" ]
    then
	if_wifi=${1}
fi


#Generating configuration files
sed -i "s/interface.*/interface=${if_wifi}/" ap.conf
sed -i "s/interface.*/interface=${if_wifi}/" dnsmasq.conf
sed -i "s/dhcp-range.*/dhcp-range=${ip_first}.100,${ip_first}.200,12h/" dnsmasq.conf
sed -i "s/wpa_passphrase=.*/wpa_passphrase=${pass}/" $conf_file
sed -i "s/ssid=.*/ssid=${ssid}/" $conf_file

trap ctrl_c INT
function ctrl_c(){
    echo
    echo
    echo -n "-> Killing processes... "
    killall dnsmasq > /dev/null
    echo "done"
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

echo ""
echo ""
echo "**********  hostapd starts here  **********"
hostapd $conf_file

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
