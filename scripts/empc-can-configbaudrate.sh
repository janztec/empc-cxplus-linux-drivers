#!/bin/bash

export LC_ALL=C

if [ $EUID -ne 0 ]; then
    echo "This script should be run as root." > /dev/stderr
    exit 1
fi

IP=

CANS=$()

for can in 0 1
do

BAUDRATE=$(whiptail --title "Configure CAN$can baudrate" --radiolist \
"What is the baudrate of can$can bus?" 15 60 8 \
"1000" "1000 kBit/s" OFF \
"500" "500 kBit/s" OFF \
"250" "250 kBit/s (default)" ON \
"125" "125 kBit/s" OFF \
"100" "100 kBit/s" OFF \
"50" "50 kBit/s" OFF \
"20" "20 kBit/s" OFF \
"10" "10 kBit/s" OFF 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ]; then

 while IFS= read -r line
 do
  [[ ! "$line" =~ "can$can" ]] && echo "$line"
 done </etc/network/interfaces > /tmp/interfaces
 mv /tmp/interfaces /etc/network/interfaces


 echo "# can$can" >>/etc/network/interfaces
 echo "allow-hotplug can$can" >>/etc/network/interfaces
 echo "iface can$can inet manual" >>/etc/network/interfaces
 echo -e "\tpre-up /sbin/ip link set can$can type can bitrate $BAUDRATE""000 triple-sampling on" >>/etc/network/interfaces
 echo -e "\tup /sbin/ip link set can$can up txqueuelen 1000" >>/etc/network/interfaces
 echo -e "\tdown /sbin/ip link set can$can down" >>/etc/network/interfaces

fi

done
