# Scenariusz 2: Blokowanie ruchu (iptables REJECT – TCP RST)

Aktywny DoS na wybrane usługi. PS w trybie NAT odrzuca pakiety przez `iptables -j REJECT --reject-with tcp-reset`. Ofiara widzi `ERR_CONNECTION_RESET` – dla niej wygląda to jak awaria serwera.

Blokowanie po porcie (80, 443) lub po treści (`-m string --string "facebook"`).

**Switch:** 1 | **NETMODE:** NAT | **Mechanizm:** `iptables -A FORWARD -p tcp --dport 443 -j REJECT --reject-with tcp-reset`

### Wymagany sprzęt

PS MK1, 2× kable Ethernet, powerbank, laptop ofiary.
