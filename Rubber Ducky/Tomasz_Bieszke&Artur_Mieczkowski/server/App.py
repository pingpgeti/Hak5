import customtkinter as ctk
from pathlib import Path

class App(ctk.CTk):
    def __init__(self, dq):
        super().__init__()
        self.dataQueue = dq
        self.title("User logs manager")
        self.geometry("850x500")

        self.users = {}
        self.loadData()
        self.sideBarButtons = {}

        # Konfiguracja siatki (Grid) - 1 wiersz, 2 kolumny
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        # --- LEWA STRONA: Lista ---
        self.sidebar_frame = ctk.CTkScrollableFrame(self, width=250, corner_radius=0)
        self.sidebar_frame.grid(row=0, column=0, sticky="nsew")
        self.label_list = ctk.CTkLabel(self.sidebar_frame, text="Użytkownicy", font=ctk.CTkFont(size=16, weight="bold"))
        self.label_list.pack(pady=10)

        # Przycisk dla każdego użytkownika
        for name in self.users.keys():
            btn = ctk.CTkButton(self.sidebar_frame, text=name,
                                fg_color="transparent", text_color=("gray10", "gray90"),
                                hover_color=("gray70", "gray30"),
                                anchor="w",
                                command=lambda n=name: self.show_user_info(n))
            btn.pack(fill="x", padx=10, pady=2)
            self.sideBarButtons.update({name: btn})

        self.content_frame = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.content_frame.grid(row=0, column=1, sticky="nsew", padx=20, pady=20)

        self.info_label = ctk.CTkLabel(self.content_frame, text="Wybierz użytkownika z listy",
                                       font=ctk.CTkFont(size=14))
        self.info_label.pack(expand=True)
        self.updateData()

    def show_user_info(self, name):
        for widget in self.content_frame.winfo_children():
            widget.destroy()

        ctk.CTkLabel(self.content_frame, text=name, font=("Arial", 20, "bold")).pack(pady=10)
        self.info_text = ctk.CTkLabel(
            self.content_frame,
            text=self.users[name],
            wraplength=500,
            justify="left"
        )
        self.info_text.pack(pady=10, fill="both", expand=True)
    def loadData(self):
        folderPath = Path("userLogs")
        for filePath in folderPath.glob("*.txt"):
            try:
                with open(filePath, "r", encoding="utf-8") as file:
                    content = file.read()
                    user_name = filePath.stem
                    self.users.update({user_name: content})
            except Exception as e:
                print(f"Błąd przy czytaniu {filePath}: {e}")

    def updateData(self):
        while not self.dataQueue.empty():
            user, data = self.dataQueue.get()
            if user not in self.users.keys():
                self.users.update({user: data})
            else:
                self.users[user] += data
            self.updateLeftButtons(user)
            self.updateRightContent(user)
        self.after(5000, self.updateData)

    def updateLeftButtons(self, name):
        if name not in self.sideBarButtons:
            btn = ctk.CTkButton(self.sidebar_frame, text=name,
                                fg_color="transparent", text_color=("gray10", "gray90"),
                                hover_color=("gray70", "gray30"),
                                anchor="w",
                                command=lambda n=name: self.show_user_info(n))
            btn.pack(fill="x", padx=10, pady=2)
            self.sideBarButtons[name] = btn

    def updateRightContent(self, name):
        self.show_user_info(name)
        return

    def genTestData(self):
        dlugaWiadomosc = ('Tutaj ejst bardzo długa wiadomosc o kotku i myszce itd nie wiem co dalej pisac byleby zape'
                          'lnilowystarczajaco ekran blalbalbalblablab')
        for i in range(25):
            self.users.update({f"user no{i}": f"{dlugaWiadomosc}, tutaj numerki:{i**2}"*10})
        return