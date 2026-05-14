# Scenariusz 3: DNS Spoofing – Przekierowanie na phishingową stronę

Aktywny atak MITM. PS w trybie `NETMODE NAT` przechwytuje zapytania DNS ofiary przez `iptables REDIRECT` + `dnsmasq` i zwraca fałszywy IP. Ofiara wpisuje `neverssl.com`, trafia na serwer phishingowy na PS.

**Switch:** 2 | **NETMODE:** NAT | **Mechanizm:** `iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-port 53` + dnsmasq

### Dlaczego NIE facebook.com?

Domeny z HSTS preload (google.com, facebook.com) wymuszają HTTPS – DNS spoofing nie działa. Używamy: `neverssl.com`, `httpbin.org`, `testphp.vulnweb.com`.

### Wymagany sprzęt

PS MK1, 2× kable Ethernet, powerbank, laptop ofiary, laptop prezentera.
