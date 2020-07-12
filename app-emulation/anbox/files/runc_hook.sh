#!/bin/bash

params=`cat`
container_pid=`echo $params | sed -r 's/.*"pid": ([0-9]+).*/\1/g'`
exist_dev=`ip route get 8.8.8.8 | sed -r 's/.* dev ([^ ]+).*/\1/g' | head -n 1`
ip_range=192.168.88

sudo ip link add vnet0 type veth peer name vnet1
sudo ip addr add ${ip_range}.1/24 dev vnet0
sudo ip link set vnet0 up

sudo ip link set netns ${container_pid} dev vnet1
nsenter -t ${container_pid} -n ip addr add ${ip_range}.2/24 dev vnet1
nsenter -t ${container_pid} -n ip link set vnet1 up
nsenter -t ${container_pid} -n ip route add default via ${ip_range}.1 dev vnet1

iptables -A FORWARD -o $exist_dev -i vnet0 -j ACCEPT
iptables -A FORWARD -i $exist_dev -o vnet0 -j ACCEPT
iptables -t nat -A POSTROUTING -s ${ip_range}.2/24 -o $exist_dev -j MASQUERADE