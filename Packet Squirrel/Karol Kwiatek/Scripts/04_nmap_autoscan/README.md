# Scenariusz 4: Nmap Autoscan – Automatyczne skanowanie sieci z powiadomieniem Discord

Autonomiczny atak rozpoznawczy. PS pobiera IP przez DHCP na `eth1`, wykrywa podsieć, skanuje `nmap -F -sV` i wysyła wyniki na Discord (webhook) + zapisuje na pendrive. Atakujący nie potrzebuje dostępu do sieci ani SSH.

**Switch:** 1 | **NETMODE:** (brak, `udhcpc -i eth1`) | **Wymaga:** Discord webhook, zainstalowany `nmap` (`opkg install nmap`)

### Wymagany sprzęt

PS MK1, pendrive USB-A (NTFS/EXT4), 2× kable Ethernet, powerbank, webhook Discord.
