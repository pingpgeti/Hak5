import io
import os
import time
import tkinter as tk

import numpy as np
import requests
from get_stream import authenticate, fetch_one_image_bytes
from PIL import Image, ImageDraw, ImageTk

try:
    import cv2
except ImportError as exc:
    raise SystemExit("Missing dependency: opencv-python. Install with: py -m pip install opencv-python") from exc

SITE_ID = 1
DEVICE_ID = 4
REFRESH_SECONDS = 10
MATCH_THRESHOLD = 0.9
TEMPLATE_PATH = "target.bmp"
OUTPUT_DIR = "output"


def detect_target_in_image(
    image: Image.Image,
    template_bgr: np.ndarray,
    threshold: float = MATCH_THRESHOLD,
) -> tuple[bool, float, tuple[int, int], tuple[int, int]]:
    frame_bgr = cv2.cvtColor(np.array(image.convert("RGB")), cv2.COLOR_RGB2BGR)
    result = cv2.matchTemplate(frame_bgr, template_bgr, cv2.TM_CCOEFF_NORMED)
    _, max_score, _, max_loc = cv2.minMaxLoc(result)

    template_h, template_w = template_bgr.shape[:2]
    detected = max_score >= threshold
    return detected, float(max_score), max_loc, (template_w, template_h)


def main() -> None:
    template_bgr = cv2.imread(TEMPLATE_PATH, cv2.IMREAD_COLOR)
    if template_bgr is None:
        raise FileNotFoundError(f"Could not load template file: {TEMPLATE_PATH}")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    session, token = authenticate()

    root = tk.Tk()
    root.title("Camera Stream")

    image_label = tk.Label(root, text="Loading image...")
    image_label.pack(padx=12, pady=12)

    status_label = tk.Label(root, text="", fg="black")
    status_label.pack(padx=12, pady=(0, 6))

    last_updated_label = tk.Label(root, text="", fg="gray")
    last_updated_label.pack(padx=12, pady=(0, 12))

    def refresh_image() -> None:
        nonlocal session, token

        try:
            image_bytes = fetch_one_image_bytes(
                site_id=SITE_ID,
                device_id=DEVICE_ID,
                session=session,
                token=token,
            )
            full_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

            detected, score, top_left, size = detect_target_in_image(full_image, template_bgr)
            display_image = full_image.copy()

            timestamp = time.strftime("%Y%m%d_%H%M%S")
            last_updated = time.strftime("%Y-%m-%d %H:%M:%S")

            if detected:
                x, y = top_left
                w, h = size
                draw = ImageDraw.Draw(display_image)
                draw.rectangle((x, y, x + w, y + h), outline="red", width=4)

                output_path = os.path.join(OUTPUT_DIR, f"detected_{timestamp}.png")
                full_image.save(output_path, format="PNG")
                status_text = f"Target found (score={score:.3f}). Saved: {output_path}"
            else:
                status_text = f"No target (score={score:.3f})"

            display_image.thumbnail((960, 720), Image.Resampling.LANCZOS)

            photo = ImageTk.PhotoImage(display_image)
            image_label.configure(image=photo, text="")
            image_label.image = photo
            status_label.configure(text=status_text)
            last_updated_label.configure(text=f"Last updated: {last_updated}")

        except requests.HTTPError as exc:
            code = exc.response.status_code if exc.response is not None else "unknown"
            if code in (401, 403):
                try:
                    session, token = authenticate(session=session)
                    status_label.configure(text="Session refreshed. Retrying...")
                except Exception as auth_exc:
                    status_label.configure(text=f"Re-auth failed: {auth_exc}")
            else:
                status_label.configure(text=f"HTTP error: {code}")
            last_updated_label.configure(text=f"Last updated: {time.strftime('%Y-%m-%d %H:%M:%S')}")

        except Exception as exc:
            status_label.configure(text=f"Update failed: {exc}")
            last_updated_label.configure(text=f"Last updated: {time.strftime('%Y-%m-%d %H:%M:%S')}")

        root.after(REFRESH_SECONDS * 1000, refresh_image)

    refresh_image()
    root.mainloop()


if __name__ == "__main__":
    main()
