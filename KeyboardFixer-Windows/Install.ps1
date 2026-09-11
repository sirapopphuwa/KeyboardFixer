Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$applicationName = 'KeyboardFixer'
$installDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) $applicationName
$programsDirectory = [Environment]::GetFolderPath('Programs')
$startupDirectory = [Environment]::GetFolderPath('Startup')
$startMenuLink = Join-Path $programsDirectory 'KeyboardFixer.lnk'
$startupLink = Join-Path $startupDirectory 'KeyboardFixer.lnk'

if (-not (Test-Path $installDirectory)) {
    New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
}

foreach ($fileName in @(
    'KeyboardFixer.Core.ps1',
    'KeyboardFixer.ps1',
    'Open KeyboardFixer.bat',
    'Start KeyboardFixer.bat',
    'Test-KeyboardFixer.ps1',
    'README.md',
    'Uninstall.ps1',
    'Uninstall KeyboardFixer.bat'
)) {
    $sourcePath = Join-Path $PSScriptRoot $fileName
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination (Join-Path $installDirectory $fileName) -Force
    }
}

$shell = New-Object -ComObject WScript.Shell
$powershellPath = Join-Path $PSHOME 'powershell.exe'
$installedScript = Join-Path $installDirectory 'KeyboardFixer.ps1'
$startupArguments = "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installedScript`""
$openArguments = "$startupArguments -ShowWindow"

$startMenuShortcut = $shell.CreateShortcut($startMenuLink)
$startMenuShortcut.TargetPath = $powershellPath
$startMenuShortcut.Arguments = $openArguments
$startMenuShortcut.WorkingDirectory = $installDirectory
$startMenuShortcut.Description = 'Open KeyboardFixer'
$startMenuShortcut.Save()

$startupShortcut = $shell.CreateShortcut($startupLink)
$startupShortcut.TargetPath = $powershellPath
$startupShortcut.Arguments = $startupArguments
$startupShortcut.WorkingDirectory = $installDirectory
$startupShortcut.Description = 'Start KeyboardFixer at login'
$startupShortcut.Save()

Start-Process -FilePath $powershellPath -ArgumentList $openArguments -WorkingDirectory $installDirectory
[Windows.Forms.MessageBox]::Show(
    'KeyboardFixer is installed. Look for its keyboard icon in the notification area near the clock.',
    'KeyboardFixer installed'
) | Out-Null
