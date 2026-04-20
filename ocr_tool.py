#!/usr/bin/env python3
"""Screen OCR Tool - system tray app, Ctrl+Shift+S to capture region and OCR"""

import sys
import os
import threading
import queue
import tkinter as tk
from PIL import Image, ImageDraw
import mss
import pyperclip
import pystray
from pynput import keyboard as pynput_keyboard
import pytesseract


def _setup_tesseract() -> None:
    """Locate Tesseract: prefer a Tesseract-OCR folder next to the exe, fall back to system install."""
    if getattr(sys, 'frozen', False):
        base = os.path.dirname(sys.executable)
    else:
        base = os.path.dirname(os.path.abspath(__file__))

    portable = os.path.join(base, 'Tesseract-OCR', 'tesseract.exe')
    if os.path.exists(portable):
        pytesseract.pytesseract.tesseract_cmd = portable
        # Tell Tesseract where its tessdata lives when running from a portable folder
        os.environ.setdefault('TESSDATA_PREFIX', os.path.join(base, 'Tesseract-OCR'))
    else:
        pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'


_setup_tesseract()

task_queue: queue.Queue = queue.Queue()
tray_icon: pystray.Icon | None = None
is_capturing = False


def create_tray_image() -> Image.Image:
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([2, 2, size - 2, size - 2], fill=(30, 144, 255, 255), outline=(20, 100, 200, 255), width=2)
    # White "T" for text/OCR
    draw.rectangle([12, 14, 52, 22], fill='white')
    draw.rectangle([28, 22, 36, 50], fill='white')
    return img


def show_selection_window(root: tk.Tk, on_complete) -> None:
    """Display semi-transparent fullscreen overlay for region selection."""
    with mss.mss() as sct:
        mon = sct.monitors[0]
        offset_x = mon['left']
        offset_y = mon['top']
        total_w = mon['width']
        total_h = mon['height']

    win = tk.Toplevel(root)
    win.overrideredirect(True)
    win.attributes('-topmost', True)
    win.attributes('-alpha', 0.35)
    win.geometry(f"{total_w}x{total_h}+{offset_x}+{offset_y}")
    win.configure(bg='black')

    canvas = tk.Canvas(win, bg='black', cursor='crosshair', highlightthickness=0)
    canvas.pack(fill=tk.BOTH, expand=True)

    state = {'start_x': None, 'start_y': None, 'rect_id': None, 'done': False}

    def finish(region):
        if state['done']:
            return
        state['done'] = True
        win.destroy()
        on_complete(region)

    def on_press(event):
        state['start_x'] = event.x
        state['start_y'] = event.y
        if state['rect_id']:
            canvas.delete(state['rect_id'])

    def on_drag(event):
        if state['rect_id']:
            canvas.delete(state['rect_id'])
        if state['start_x'] is not None:
            state['rect_id'] = canvas.create_rectangle(
                state['start_x'], state['start_y'], event.x, event.y,
                outline='#FF3333', width=2, dash=(6, 3)
            )

    def on_release(event):
        if state['start_x'] is None:
            finish(None)
            return
        x1 = min(state['start_x'], event.x) + offset_x
        y1 = min(state['start_y'], event.y) + offset_y
        x2 = max(state['start_x'], event.x) + offset_x
        y2 = max(state['start_y'], event.y) + offset_y
        if (x2 - x1) > 5 and (y2 - y1) > 5:
            finish({'left': x1, 'top': y1, 'width': x2 - x1, 'height': y2 - y1})
        else:
            finish(None)

    def on_escape(event):
        finish(None)

    canvas.bind('<ButtonPress-1>', on_press)
    canvas.bind('<B1-Motion>', on_drag)
    canvas.bind('<ButtonRelease-1>', on_release)
    win.bind('<Escape>', on_escape)

    win.focus_force()
    canvas.focus_set()


def perform_ocr(region: dict) -> None:
    """Capture region, run OCR, copy text to clipboard, notify via tray."""
    global is_capturing
    try:
        with mss.mss() as sct:
            screenshot = sct.grab(region)
        img = Image.frombytes('RGB', screenshot.size, screenshot.rgb)
        text = pytesseract.image_to_string(img).strip()
        if text:
            pyperclip.copy(text)
            if tray_icon:
                tray_icon.notify(f'Copied {len(text)} characters to clipboard', 'OCR Tool')
        else:
            if tray_icon:
                tray_icon.notify('No text detected in selection', 'OCR Tool')
    except Exception as exc:
        if tray_icon:
            tray_icon.notify(f'Error: {str(exc)[:80]}', 'OCR Tool')
    finally:
        is_capturing = False


def do_capture(root: tk.Tk) -> None:
    """Initiate capture flow; must be called from tkinter main thread."""
    global is_capturing
    if is_capturing:
        return
    is_capturing = True

    def on_region_selected(region):
        global is_capturing
        if region is None:
            is_capturing = False
            return
        threading.Thread(target=perform_ocr, args=(region,), daemon=True).start()

    show_selection_window(root, on_region_selected)


def check_queue(root: tk.Tk) -> None:
    """Drain task queue; rescheduled every 100 ms from tkinter mainloop."""
    try:
        while True:
            task = task_queue.get_nowait()
            if task == 'capture':
                do_capture(root)
            elif task == 'quit':
                if tray_icon:
                    tray_icon.stop()
                root.destroy()
                return
    except queue.Empty:
        pass
    root.after(100, lambda: check_queue(root))


def on_hotkey() -> None:
    task_queue.put('capture')


def start_tray(root: tk.Tk) -> None:
    global tray_icon

    def on_capture(icon, item):
        task_queue.put('capture')

    def on_exit(icon, item):
        task_queue.put('quit')

    menu = pystray.Menu(
        pystray.MenuItem('Capture (Ctrl+Shift+S)', on_capture, default=True),
        pystray.MenuItem('Exit', on_exit),
    )

    icon_img = create_tray_image()
    tray_icon = pystray.Icon('OCRTool', icon_img, 'Screen OCR Tool', menu)
    tray_icon.run()


def start_hotkey_listener() -> None:
    with pynput_keyboard.GlobalHotKeys({'<ctrl>+<shift>+s': on_hotkey}) as listener:
        listener.join()


def main() -> None:
    root = tk.Tk()
    root.withdraw()
    root.wm_attributes('-toolwindow', True)

    tray_thread = threading.Thread(target=start_tray, args=(root,), daemon=True)
    tray_thread.start()

    hotkey_thread = threading.Thread(target=start_hotkey_listener, daemon=True)
    hotkey_thread.start()

    root.after(100, lambda: check_queue(root))
    root.mainloop()


if __name__ == '__main__':
    main()
