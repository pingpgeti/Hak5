#!/bin/bash
# Packet Sniffing – switch=1, NETMODE TRANSPARENT

LOOT_DIR="/mnt/loot/tcpdump"
INTERFACE="br-lan"

LED SETUP
sleep 2
mkdir -p "$LOOT_DIR" &> /dev/null

if [ ! -d "$LOOT_DIR" ]; then
    LED FAIL
    exit 1
fi

NETMODE TRANSPARENT
sleep 5

AVAIL=$(df -m "$LOOT_DIR" | tail -1 | awk '{print $4}')
if [ "$AVAIL" -lt 100 ]; then
    LED R 200
    sleep 2
fi

TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
PCAP_FILE="${LOOT_DIR}/dump_${TIMESTAMP}.pcap"

LED ATTACK

tcpdump -i "$INTERFACE" -w "$PCAP_FILE" &>/dev/null &
TPID=$!

while kill -0 $TPID 2>/dev/null; do
    AVAIL=$(df -m "$LOOT_DIR" | tail -1 | awk '{print $4}')
    if [ "$AVAIL" -lt 50 ]; then
        kill $TPID
        break
    fi
    sleep 10
done &
MONPID=$!

NO_LED=true BUTTON

kill $TPID 2>/dev/null
wait $TPID 2>/dev/null
kill $MONPID 2>/dev/null
wait $MONPID 2>/dev/null

sync

LED G SUCCESS
sleep 2
LED OFF
halt
