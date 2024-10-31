#!/bin/bash

# Usage: ./create.sh <EXTERNAL IP> <MITM PORT>
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <EXTERNAL IP> <MITM PORT>"
fi

EXTERN_IP=$1
MITM_PORT=$2

# Randomly select configuration
NAME=$((1 + "$RANDOM" % 3))
RAM=$((1 + "$RANDOM" % 2))
CPU=$((1 + "$RANDOM" % 2))

RAM_AMT=$((RAM * 2147483648))
CPU_AMT=$((CPU * 512))

FILENAME=""

# Create name variable based on random nums
if [ "$NAME" == 1 ]; then
    NAME=bank
    FILENAME="bank_honey.json"
elif [ "$NAME" == 2 ]; then
    NAME=hospital
    FILENAME="hospital_honey.json"
else
    NAME=restaurant
    FILENAME="restaurant_honey.json"
fi

# Create RAM variable based on random nums
if [ "$RAM" == 1 ]; then
    RAM=_low_
else
    RAM=_high_
fi

# Create CPU variable based on random nums
if [ "$CPU" == 1 ]; then
    CPU=low
else
    CPU=high
fi

EPOCH_TIME=$(date +%s)
NEW_FOLDER="${NAME}${RAM}${CPU}"
NEW_CONTAINER="${NEW_FOLDER}_${EPOCH_TIME}"

sudo lxc-create -n "$NEW_CONTAINER" -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n "$NEW_CONTAINER"

# Waiting for container to start
while ! sudo lxc-info -n "$NEW_CONTAINER" | grep -q "RUNNING"; do
    sleep 1
done

# Set RAM and CPU Limit
sudo lxc-cgroup -n "$NEW_CONTAINER" memory.limit_in_bytes "$RAM_AMT"
sudo lxc-cgroup -n "$NEW_CONTAINER" cpu.shares "$CPU_AMT"

# Fetch the internal IP and store it for routing
while true; do
    IP=$(sudo lxc-info -n "$NEW_CONTAINER" -iH 2>/dev/null)

    if [ -n "$IP" ]; then
        break
    fi

    sleep 1
done

# Setup network configurations
sudo ip addr add "$EXTERN_IP"/24 brd + dev eth3

# Install binaries on the honeypot
sudo lxc-attach -n "$NEW_CONTAINER" -- bash -c "sudo apt-get update"
sudo lxc-attach -n "$NEW_CONTAINER" -- bash -c "sudo apt-get install openssh-server -y"
sudo lxc-attach -n "$NEW_CONTAINER" -- bash -c "sudo systemctl enable ssh --now"

# Add the honey to the new container
sudo cp ./honey/$FILENAME /var/lib/lxc/$NEW_CONTAINER/rootfs/home

# Insert MITM rule
sudo iptables -t nat -I PREROUTING -s 0.0.0.0/0 -d $EXTERN_IP -j DNAT --to-destination $IP
sudo iptables -t nat -I POSTROUTING -s $IP -d 0.0.0.0/0 -j SNAT --to-source $EXTERN_IP
sudo iptables -t nat -I PREROUTING -s 0.0.0.0/0 -d "$EXTERN_IP" --protocol tcp --dport 22 -j DNAT --to-destination 10.0.3.1:"$MITM_PORT"

# Allow routing of localnet traffic
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

# Set up MITM server
sudo forever -l ~/mitm_logs/"$NEW_FOLDER"/"$NEW_CONTAINER".log start -a /home/student/MITM/mitm.js -n "$NEW_CONTAINER" -i "$IP" -p "$MITM_PORT" --mitm-ip 10.0.3.1 --auto-access --auto-access-fixed 3 --debug
