# Keylogger — projekt akademicki

Projekt wykonany w ramach zajęć na studiach. Jego celem jest demonstracja działania programu rejestrującego naciśnięcia klawiszy, komunikacji pomiędzy klientem i serwerem oraz automatyzacji procesu uruchamiania programu za pomocą urządzenia HID.

> **Uwaga:** Projekt przeznaczony jest wyłącznie do celów edukacyjnych i laboratoryjnych. Należy uruchamiać go tylko na systemach, do których posiada się odpowiednie uprawnienia.

---

## Struktura projektu

```text
.
├── client/
│   ├── duckyScripts/
│   │   ├── duckyScript.txt
│   │   ├── oneLiner.c
│   │   ├── oneLiner.txt
│   │   └── prepareCodeForCmd.py
│   │
│   ├── logger.c
│   ├── logger.exe
│   ├── logger2.exe
│   ├── oneLiner.c
│   └── oneLiner.exe
│
├── server/
│   ├── __pycache__/
│   ├── .idea/
│   ├── userlogs/
│   ├── venv/
│   ├── App.py
│   └── main.py
│
├── .gitignore
└── README.md
```

---

# Client

Folder `client` zawiera komponenty odpowiedzialne za działanie programu po stronie klienta.

## `logger.c`

Główny program napisany w języku C w normalnej, wieloliniowej postaci.

Jego zadaniem jest obsługa mechanizmu rejestrowania naciśnięć klawiszy w środowisku testowym.

Plik ten stanowi wersję źródłową programu, która może być następnie wykorzystana do przygotowania wersji jednolinijkowej.

## `logger.exe`

Skompilowana wersja programu `logger.c`.

## `logger2.exe`

Dodatkowy plik wykonywalny związany z częścią kliencką projektu.

## `oneLiner.c`

Jednolinijkowa wersja programu napisanego w języku C.

W porównaniu do `logger.c` cały kod programu został zapisany w jednej linii. Ułatwia to późniejsze przygotowanie kodu do automatycznego wprowadzenia przez interfejs wiersza poleceń.

## `oneLiner.exe`

Skompilowana wersja `oneLiner.c`.

---

# DuckyScripts

Folder `client/duckyScripts` zawiera pliki związane z przygotowaniem kodu do automatycznego wprowadzania za pomocą urządzenia HID zgodnego z koncepcją USB Rubber Ducky.

```text
duckyScripts/
├── duckyScript.txt
├── oneLiner.c
├── oneLiner.txt
└── prepareCodeForCmd.py
```

## `duckyScript.txt`

Skrypt napisany w języku **DuckyScript**.

Jest przeznaczony do demonstracji automatyzacji wprowadzania przygotowanego kodu w kontrolowanym środowisku testowym.

Skrypt może zostać następnie przekonwertowany do formatu binarnego `.bin` przy użyciu narzędzi udostępnianych przez Hak5.

## `oneLiner.c`

Kopia jednolinijkowej wersji programu C wykorzystywanej w procesie przygotowywania skryptu.

## `oneLiner.txt`

Przygotowana wersja kodu przeznaczona do wpisania do wiersza poleceń.

W pliku znajdują się odpowiednio przygotowane znaki specjalne oraz sekwencje escape wymagane do poprawnego przekazania kodu jako tekstu.

## `prepareCodeForCmd.py`

Program pomocniczy napisany w Pythonie.

Jego zadaniem jest przetworzenie kodu C znajdującego się w `oneLiner.c` do postaci zapisanej w `oneLiner.txt`.

Podczas przetwarzania program m.in.:

- przygotowuje kod do przekazania przez `cmd`,
- dodaje wymagane backslashe,
- odpowiednio obsługuje znaki specjalne,
- generuje gotową reprezentację tekstową programu.

Proces można przedstawić następująco:

```text
oneLiner.c
    │
    ▼
prepareCodeForCmd.py
    │
    ▼
oneLiner.txt
    │
    ▼
duckyScript.txt
    │
    ▼
plik .bin
```

---

# Server

Folder `server` zawiera część serwerową projektu napisaną w języku **Python**.

```text
server/
├── userlogs/
├── App.py
└── main.py
```

## `App.py`

Główny moduł aplikacji serwerowej.

Odpowiada za obsługę aplikacji oraz komunikację z komponentem klienckim.

## `main.py`

Plik uruchamiający aplikację serwerową.

Stanowi punkt wejścia do części serwerowej projektu.

## `userlogs/`

Folder przeznaczony do przechowywania odebranych logów.

Dane są zapisywane w postaci plików tekstowych.

---

# Ogólny przepływ projektu

Całość projektu można przedstawić za pomocą następującego schematu:

```text
                  CLIENT
                    │
                    │
          ┌─────────▼─────────┐
          │     logger.c      │
          │                   │
          │ program w języku C│
          └─────────┬─────────┘
                    │
                    ▼
              oneLiner.c
                    │
                    ▼
        prepareCodeForCmd.py
                    │
                    ▼
              oneLiner.txt
                    │
                    ▼
            DuckyScript.txt
                    │
                    ▼
             urządzenie HID
                    │
                    ▼
          środowisko testowe
                    │
                    ▼
                  SERVER
                    │
             ┌──────▼──────┐
             │   App.py    │
             │   main.py   │
             └──────┬──────┘
                    │
                    ▼
                userlogs/
                    │
                    ▼
               pliki .txt
```

---

# Wykorzystane technologie

| Technologia | Zastosowanie |
|---|---|
| **C** | Implementacja programu klienckiego |
| **Python** | Serwer oraz program pomocniczy |
| **DuckyScript** | Automatyzacja wprowadzania danych |
| **USB HID** | Demonstracja automatyzacji wejścia |
| **CMD** | Przygotowanie i przekazywanie kodu |
| **TXT** | Przechowywanie logów i danych pośrednich |
| **EXE** | Skompilowane wersje programów C |

---

# Cel projektu

Głównym celem projektu jest zaprezentowanie wybranych zagadnień związanych z bezpieczeństwem systemów komputerowych.

Projekt pozwala zapoznać się z:

- obsługą wejścia z klawiatury,
- działaniem interfejsów HID,
- językiem DuckyScript,
- zagrożeniami związanymi z nieautoryzowanymi urządzeniami HID.

---

# Bezpieczeństwo

Projekt powinien być wykorzystywany wyłącznie w kontrolowanym środowisku laboratoryjnym.

Podczas testów należy używać wyłącznie danych demonstracyjnych i komputerów, na których użytkownik posiada odpowiednie uprawnienia.

Nie należy wykorzystywać projektu do:

- pozyskiwania cudzych haseł,
- monitorowania innych osób bez ich zgody,
- zbierania poufnych informacji,
- instalowania oprogramowania na nieautoryzowanych komputerach.

---

# Informacje o projekcie

**Autor:** `Tomasz Bieszke`

**Kierunek:** `Informatyka`

---

## Zastrzeżenie

Projekt został przygotowany wyłącznie w celach edukacyjnych i badawczych.

Wszystkie testy powinny być wykonywane za zgodą właściciela badanego systemu oraz w środowisku przeznaczonym do testów bezpieczeństwa.
```