@echo off
setlocal enabledelayedexpansion

echo ============================================
echo  Screen OCR Tool ^| Release Builder
echo ============================================
echo.

:: ── Auto-read current version from setup.iss ──
for /f "delims=" %%v in ('powershell -NoProfile -Command ^
    "(Get-Content setup.iss) | Where-Object { $_ -match '#define AppVersion' } | ForEach-Object { $_ -replace '.*\x22(.*)\x22.*', '$1' }"') do set CURRENT=%%v

for /f "tokens=1,2 delims=." %%a in ("%CURRENT%") do (
    set MAJOR=%%a
    set MINOR=%%b
)

:: ── Bump version ──────────────────────────────
if /i "%~1"=="major" (
    set /a MAJOR=%MAJOR%+1
    set MINOR=0
    echo Bump type: MAJOR release
) else (
    set /a MINOR=%MINOR%+1
    echo Bump type: minor release
)

set VERSION=%MAJOR%.%MINOR%
echo Previous : v%CURRENT%
echo New      : v%VERSION%
echo.

:: ── Paths ─────────────────────────────────────
set PYTHON=%LOCALAPPDATA%\Python\pythoncore-3.14-64\python.exe
set PYINSTALLER=%LOCALAPPDATA%\Python\pythoncore-3.14-64\Scripts\pyinstaller.exe

set ISCC=
if exist "C:\Program Files (x86)\Inno Setup 6\iscc.exe" set ISCC=C:\Program Files (x86)\Inno Setup 6\iscc.exe
if exist "C:\Program Files\Inno Setup 6\iscc.exe"       set ISCC=C:\Program Files\Inno Setup 6\iscc.exe
if "%ISCC%"=="" (
    echo ERROR: Inno Setup 6 not found. Install from https://jrsoftware.org/isdl.php
    exit /b 1
)

:: ── 1. Dependencies ───────────────────────────
echo [1/4] Installing Python dependencies...
"%PYTHON%" -m pip install --quiet pillow pynput pystray pyperclip mss pyinstaller
if errorlevel 1 ( echo ERROR: pip install failed. & exit /b 1 )

:: ── 2. PyInstaller ────────────────────────────
echo [2/4] Building executable...
"%PYINSTALLER%" --onefile --noconsole ^
    --name OCRTool ^
    --hidden-import=pystray._win32 ^
    --hidden-import=pynput.keyboard._win32 ^
    --hidden-import=pynput.mouse._win32 ^
    --hidden-import=mss.windows ^
    ocr_tool.py >build_log.txt 2>&1
if not exist "dist\OCRTool.exe" (
    echo BUILD FAILED — see build_log.txt
    exit /b 1
)

:: ── 3. Bundle Tesseract ───────────────────────
echo [3/4] Bundling Tesseract...
set TESS_SRC=C:\Program Files\Tesseract-OCR
if not exist "%TESS_SRC%\tesseract.exe" set TESS_SRC=%LOCALAPPDATA%\ScreenOCRTool\Tesseract-OCR
if not exist "%TESS_SRC%\tesseract.exe" set TESS_SRC=%LOCALAPPDATA%\Screen OCR Tool\Tesseract-OCR
if exist "%TESS_SRC%\tesseract.exe" (
    mkdir "dist\Tesseract-OCR\tessdata" 2>nul
    xcopy /Y /E /Q "%TESS_SRC%\*" "dist\Tesseract-OCR\" >nul
) else (
    echo WARNING: Tesseract not found — using existing dist\Tesseract-OCR if present.
)

:: ── 4. Update setup.iss + compile installer ───
echo [4/4] Compiling installer (v%VERSION%)...
"%PYTHON%" -c "import re; d=open('setup.iss',encoding='utf-8').read(); d=re.sub(r'#define AppVersion \"[^\"]*\"','#define AppVersion \"%VERSION%\"',d); open('setup.iss','w',encoding='utf-8').write(d)"

mkdir installer 2>nul
"%ISCC%" /Q setup.iss
if not exist "installer\OCRTool_Setup.exe" (
    echo ERROR: Inno Setup compile failed.
    exit /b 1
)

move /Y "installer\OCRTool_Setup.exe" "installer\OCRTool_Setup_v%VERSION%.exe" >nul

echo.
echo ============================================
echo  DONE: installer\OCRTool_Setup_v%VERSION%.exe
echo ============================================
echo.
