#define AppName "KeyboardFixer"
#define AppVersion "2.1.0"
#define AppPublisher "sirapopphuwa"

[Setup]
AppId={{E9C040DF-20A0-46CC-9FA3-59C24F87A9B5}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\KeyboardFixer
DefaultGroupName=KeyboardFixer
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\build-windows-installer
OutputBaseFilename=KeyboardFixer-Windows-v{#AppVersion}-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
UninstallDisplayName=KeyboardFixer
VersionInfoVersion={#AppVersion}.0
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}

[Files]
Source: "KeyboardFixer.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "KeyboardFixer.Core.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\KeyboardFixer"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\KeyboardFixer.ps1"" -ShowWindow"; WorkingDir: "{app}"
Name: "{userstartup}\KeyboardFixer"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\KeyboardFixer.ps1"""; WorkingDir: "{app}"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\KeyboardFixer.ps1"" -ShowWindow"; WorkingDir: "{app}"; Description: "Open KeyboardFixer"; Flags: nowait postinstall skipifsilent
