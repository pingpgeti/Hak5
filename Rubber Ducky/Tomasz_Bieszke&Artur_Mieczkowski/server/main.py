import threading
import socket
import queue

from App import App

data_queue = queue.Queue()

# ============================================================    SERVER

def updateSavedUserData(user, data):
    with open(f"userLogs/{user}.txt", "a") as f:
        f.write(data)
    return

def serverThreadFunc():
    HOST = "127.0.0.1"
    PORT = 6761
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((HOST, PORT))
    server_socket.listen()

    while True:
        client_conn, client_addr = server_socket.accept()

        try:
            i = 0
            received_data = ""
            user_name = ""
            while True:
                i += 1
                chunk = client_conn.recv(1024).decode(encoding="latin-1")
                logs = ""
                if i == 1:
                    user_name, logs = chunk.split('|')
                else:
                    logs = chunk
                received_data += logs
                if "\0" in chunk:
                    break

            if received_data:
                client_conn.sendall(b"r")
                data_queue.put((user_name, received_data[:-1]))
                updateSavedUserData(user_name, logs[:-1])

        except Exception:
            print(f"Blad: {Exception}")
        finally:
            client_conn.close()

# ============================================================    MAIN

if __name__ == "__main__":
    serverThread = threading.Thread(target=serverThreadFunc, daemon=True)
    serverThread.start()

    app = App(data_queue)
    app.mainloop()