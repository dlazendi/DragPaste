# Screen OCR Tool — User Guide

## What it does

Screen OCR Tool sits in your system tray and lets you capture any text visible on screen with a single hotkey. The recognised text is copied straight to your clipboard — ready to paste anywhere.

---

## Installation

Run `OCRTool_Setup.exe` and follow the wizard. On the **Select Additional Tasks** page you can opt in to:

| Option | What it does |
|---|---|
| **Desktop shortcut** | Adds a shortcut to your desktop |
| **Start automatically with Windows** | Adds the tool to your login startup so it's always running |

The installer does **not** require administrator rights — everything is placed under your user profile.

---

## Starting the tool

- After install, the wizard offers to launch the tool immediately — tick the checkbox and click **Finish**.
- To start it manually later, open the **Start Menu → Screen OCR Tool**.
- If you enabled the startup option it will start automatically every time you log in.

---

## Capturing text

1. Press **Ctrl + Shift + S** anywhere on screen.
2. The screen dims and your cursor becomes a crosshair.
3. **Click and drag** to draw a rectangle around the text you want.
4. Release the mouse — OCR runs in the background and the recognised text is placed in your clipboard.
5. A tray notification confirms how many characters were copied, or tells you if no text was found.
6. Paste the result anywhere with **Ctrl + V**.

> Press **Escape** at any point during selection to cancel without capturing.

---

## System tray menu

The tool appears as a blue **T** icon in the system tray (bottom-right corner of your taskbar).

| Action | How |
|---|---|
| Start a capture | Double-click the icon **or** right-click → **Capture (Ctrl+Shift+S)** |
| Quit the tool | Right-click → **Exit** |

---

## Tips

- Works across **all monitors** — the dim overlay covers your entire desktop.
- The tool runs **entirely offline** — no data is sent anywhere. OCR is performed locally using the bundled Tesseract engine.
- Selection must be at least 5 × 5 pixels; anything smaller is treated as a cancelled capture.

---

## Uninstalling

**Option A — Settings:**
Open **Settings → Apps → Installed apps**, search for *Screen OCR Tool*, and click **Uninstall**.

**Option B — Start Menu:**
Open **Start Menu → Screen OCR Tool → Uninstall Screen OCR Tool**.

The uninstaller automatically removes the startup entry (if it was enabled) and all installed files.

---

## License

Screen OCR Tool is **free and open source** under the [MIT License](../LICENSE).

You are free to use, modify, and redistribute it — for personal or commercial purposes — at no cost. Attribution is appreciated but not required.

Third-party components included in the installer:

| Component | License |
|---|---|
| [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) | Apache 2.0 |
| [pytesseract](https://github.com/madmaze/pytesseract) | Apache 2.0 |
| [Pillow](https://python-pillow.org) | HPND (PIL License) |
| [pystray](https://github.com/moses-palmer/pystray) | LGPL 3.0 |
| [pynput](https://github.com/moses-palmer/pynput) | LGPL 3.0 |
| [mss](https://github.com/BoboTiG/python-mss) | MIT |
| [pyperclip](https://github.com/asweigart/pyperclip) | BSD 3-Clause |

---

## Building from source

Prerequisites: Python 3.11+, Tesseract OCR installed at `C:\Program Files\Tesseract-OCR`.

```
build.bat
```

This installs Python dependencies, builds `dist\OCRTool.exe` with PyInstaller, and copies the Tesseract binaries into `dist\Tesseract-OCR\`.

To produce the installer, open `setup.iss` in [Inno Setup 6](https://jrsoftware.org/isinfo.php) and press **Compile** (or run `iscc setup.iss` from the command line). The output is `installer\OCRTool_Setup.exe`.
