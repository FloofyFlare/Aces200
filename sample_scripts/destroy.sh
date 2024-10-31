#!/bin/bash

# Usage: ./destroy.sh <OLD CONTAINER NAME> <EXTERNAL IP> <MITM PORT>
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <EXTERNAL IP> <MITM PORT>"
fi

# Grab command line args
EXTERN_IP=$1
MITM_PORT=$2

OLD_CONTAINER=$(sudo forever list | awk -v port="$MITM_PORT" '$0 ~ port {getline; print $7}')

# Fetch old MITM IP
OLD_CONTAINER_IP=$(sudo lxc-info -n $OLD_CONTAINER -iH)

# Saving data about container (CPU I/O, RAM Usage etc)
OLD_FOLDER=$(echo "$OLD_CONTAINER" | cut -d'_' -f1-3 )
sudo lxc-info -n "$OLD_CONTAINER" | sudo tee -a ~/mitm_logs/"$OLD_FOLDER"/"$OLD_CONTAINER".log

# Stop old MITM server
ID=$(sudo forever list | awk -v port="$MITM_PORT" '$0 ~ port {getline; print $3}')
sudo forever stop "$ID"

# Remove old NAT rules (one by one)
sudo iptables -t nat -D PREROUTING -s 0.0.0.0/0 -d $EXTERN_IP -j DNAT --to-destination $OLD_CONTAINER_IP
sudo iptables -t nat -D POSTROUTING -s $OLD_CONTAINER_IP -d 0.0.0.0/0 -j SNAT --to-source $EXTERN_IP
sudo iptables -t nat -D PREROUTING -s 0.0.0.0/0 -d "$EXTERN_IP" --protocol tcp --dport 22 -j DNAT --to-destination 10.0.3.1:"$MITM_PORT"

# append lxc-info to log file

# Delete container
sudo lxc-stop -n "$OLD_CONTAINER"
sudo lxc-destroy -n "$OLD_CONTAINER"
