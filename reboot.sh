#!/bin/bash
modprobe br_netfilter
sysctl -p /etc/sysctl.conf
/bin/bash /home/student/firewall_rules.sh
#echo "firewall" > /home/student/test1
sudo ip link set dev eth3 up

#/home/student/create_container.sh 128.8.238.129
#/home/student/create_container.sh 128.8.238.90
#sudo /home/student/create_container.sh 128.8.238.141
#/home/student/create_container.sh 128.8.238.159
#/home/student/create_container.sh 128.8.238.137
sudo /home/student/create_container.sh 128.8.238.101
sudo /home/student/create_container.sh 128.8.238.111
sudo /home/student/create_container.sh 128.8.238.200
sudo /home/student/create_container.sh 128.8.238.205
