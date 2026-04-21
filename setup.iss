; Screen OCR Tool — Inno Setup 6 installer script
; https://jrsoftware.org/isinfo.php

#define AppName "Screen OCR Tool"
#define AppVersion "1.1"
#define AppPublisher "dlazendi"
#define AppExeName "OCRTool.exe"
#define AppId "{{C7F3A2B1-D948-4E6C-83F0-1A2B3C4D5E6F}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppVerName={#AppName} {#AppVersion}
DefaultDirName={localappdata}\ScreenOCRTool
DefaultGroupName={#AppName}
; Per-user install — no UAC prompt required
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
OutputDir=installer
OutputBaseFilename=OCRTool_Setup
SetupIconFile=
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
; Kill the running app before uninstalling
CloseApplications=yes
CloseApplicationsFilter={#AppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked
Name: "startup";     Description: "Start &automatically with Windows at login"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
Source: "dist\OCRTool.exe";          DestDir: "{app}";              Flags: ignoreversion
Source: "dist\Tesseract-OCR\*";      DestDir: "{app}\Tesseract-OCR"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Start Menu
Name: "{group}\{#AppName}";           Filename: "{app}\{#AppExeName}"; Comment: "Screen OCR Tool — capture text from anywhere on screen"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"

; Optional desktop shortcut
Name: "{autodesktop}\{#AppName}";     Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
; Set TESSDATA_PREFIX so Tesseract always finds its language data on any PC
Root: HKCU; Subkey: "Environment"; \
  ValueType: expandsz; ValueName: "TESSDATA_PREFIX"; \
  ValueData: "{app}\Tesseract-OCR"; \
  Flags: uninsdeletevalue

; Auto-start at login (only when the startup task is selected)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
  ValueType: string; ValueName: "{#AppName}"; \
  ValueData: """{app}\{#AppExeName}"""; \
  Flags: uninsdeletevalue; Tasks: startup

[Run]
; Offer to launch the tool at the end of the wizard
Filename: "{app}\{#AppExeName}"; \
  Description: "Launch {#AppName} now"; \
  Flags: nowait postinstall skipifsilent

[UninstallRun]
; Terminate the process before files are removed
Filename: "taskkill.exe"; Parameters: "/F /IM {#AppExeName}"; \
  Flags: runhidden; RunOnceId: "KillOCRTool"
