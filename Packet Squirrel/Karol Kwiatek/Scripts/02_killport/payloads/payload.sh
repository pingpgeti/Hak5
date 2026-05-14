#!/bin/bash
# Traffic Blocking – switch=1, NETMODE NAT, iptables REJECT tcp-reset

LED SETUP

NETMODE NAT
sleep 5

iptables -A FORWARD -p tcp --dport 80 -j REJECT --reject-with tcp-reset
iptables -A FORWARD -p tcp --dport 443 -j REJECT --reject-with tcp-reset
iptables -A FORWARD -m string --string "facebook" --algo bm -j REJECT --reject-with tcp-reset
iptables -A FORWARD -m string --string "youtube" --algo bm -j REJECT --reject-with tcp-reset

LED ATTACK

NO_LED=true BUTTON

iptables -F FORWARD

sync
LED R SUCCESS
sleep 1
LED OFF
halt
