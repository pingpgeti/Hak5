# Scenariusz 1: Packet Sniffing – Przechwytywanie ruchu sieciowego

Pasywny atak MITM. PS wpięty w trybie `NETMODE TRANSPARENT` między ofiarą a siecią zapisuje cały ruch do pliku PCAP na pendrive. Analiza offline w Wiresharku – hasła, DNS, żądania HTTP w plaintekście.

**Switch:** 1 | **NETMODE:** TRANSPARENT | **Loot:** pendrive (`/mnt/loot/dump_*.pcap`)

### Kluczowe komendy

```bash
# Podgląd przechwyconych haseł w Wiresharku
http.request.method == POST
http contains "password"
```

### Wymagany sprzęt

PS MK1, pendrive USB-A (NTFS/EXT4), 2× kable Ethernet, powerbank, laptop z Wiresharkiem.
