@echo off
setlocal
echo ============================================
echo  Screen OCR Tool ^| Build Script
echo ============================================
echo.

set PYTHON=%LOCALAPPDATA%\Python\pythoncore-3.14-64\python.exe
set PYINSTALLER=%LOCALAPPDATA%\Python\pythoncore-3.14-64\Scripts\pyinstaller.exe

echo [1/3] Installing Python dependencies...
"%PYTHON%" -m pip install pillow pynput pystray pyperclip mss pyinstaller
if errorlevel 1 (
    echo ERROR: pip install failed.
    pause
    exit /b 1
)

echo.
echo [2/3] Building with PyInstaller...
"%PYINSTALLER%" --onefile --noconsole ^
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

REM Try system install first, then fall back to the existing installed app copy
set TESS_SRC=C:\Program Files\Tesseract-OCR
if not exist "%TESS_SRC%\tesseract.exe" set TESS_SRC=%LOCALAPPDATA%\ScreenOCRTool\Tesseract-OCR
if not exist "%TESS_SRC%\tesseract.exe" set TESS_SRC=%LOCALAPPDATA%\Screen OCR Tool\Tesseract-OCR

set TESS_DST=dist\Tesseract-OCR

if not exist "%TESS_SRC%\tesseract.exe" (
    echo WARNING: Tesseract not found. Skipping — using existing dist\Tesseract-OCR if present.
    goto done
)

mkdir "%TESS_DST%\tessdata" 2>nul
xcopy /Y /E /Q "%TESS_SRC%\*" "%TESS_DST%\" >nul

:done
echo.
echo ============================================
echo  SUCCESS^^!
echo ============================================
echo.
pause
