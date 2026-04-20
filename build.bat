@echo off
setlocal
echo ============================================
echo  Screen OCR Tool ^| Build Script
echo ============================================
echo.

echo [1/3] Installing Python dependencies...
pip install pillow pytesseract pynput pystray pyperclip mss pyinstaller
if errorlevel 1 (
    echo ERROR: pip install failed. Make sure Python 3.11 is on PATH.
    pause
    exit /b 1
)

echo.
echo [2/3] Building with PyInstaller...
pyinstaller --onefile --noconsole ^
    --name OCRTool ^
    --hidden-import=pystray._win32 ^
    --hidden-import=pynput.keyboard._win32 ^
    --hidden-import=pynput.mouse._win32 ^
    --hidden-import=mss.windows ^
    ocr_tool.py

if not exist "dist\OCRTool.exe" (
    echo BUILD FAILED - review output above
    pause
    exit /b 1
)

echo.
echo [3/3] Bundling portable Tesseract...

set TESS_SRC=C:\Program Files\Tesseract-OCR
set TESS_DST=dist\Tesseract-OCR

if not exist "%TESS_SRC%\tesseract.exe" (
    echo WARNING: Tesseract not found at "%TESS_SRC%"
    echo          Install Tesseract first, or edit TESS_SRC in this script.
    goto done
)

mkdir "%TESS_DST%\tessdata" 2>nul

REM Copy the main binary and all required DLLs
copy /Y "%TESS_SRC%\tesseract.exe" "%TESS_DST%\" >nul
copy /Y "%TESS_SRC%\*.dll"         "%TESS_DST%\" >nul

REM Copy only essential language data (English + orientation detection)
copy /Y "%TESS_SRC%\tessdata\eng.traineddata" "%TESS_DST%\tessdata\" >nul
copy /Y "%TESS_SRC%\tessdata\osd.traineddata" "%TESS_DST%\tessdata\" >nul

:done
echo.
echo ============================================
echo  SUCCESS^^!
echo.
echo  Distribute the entire dist\ folder:
echo    dist\
echo      OCRTool.exe
echo      Tesseract-OCR\
echo        tesseract.exe
echo        ^*.dll
echo        tessdata\eng.traineddata
echo        tessdata\osd.traineddata
echo ============================================
echo.
pause
