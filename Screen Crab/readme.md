## Screen Crab: Student ID Grabber

This project was developed by **Miłosz Obrębski** for the **PING Scientific Club** at Gdańsk University of Technology.

---

### Overview

The project utilizes the **Hak5 Screen Crab**, a man-in-the-middle video proxy that sits between a computer and a monitor. It captures screen data and streams it over Wi-Fi without triggering OS alerts.

### The Python Script

A custom Python script automates the collection of sensitive data:

* **API Integration**: Connects to the **Cloud C2** platform to fetch images.


* **Stealth Detection**: Uses **OpenCV** to detect the university logo on the login page.


* **Automated Capture**: When the logo is detected, it saves the screenshot (containing the student ID) for analysis.

---

### Educational Use & Disclaimer

> [!IMPORTANT]
> The author of this project is not responsible for any non-educational use cases. This tool should only be used within the boundaries of the law and for educational purposes.
> 
>