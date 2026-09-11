Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$applicationName = 'KeyboardFixer'
$installDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) $applicationName
$startMenuLink = Join-Path ([Environment]::GetFolderPath('Programs')) 'KeyboardFixer.lnk'
$startupLink = Join-Path ([Environment]::GetFolderPath('Startup')) 'KeyboardFixer.lnk'

foreach ($shortcutPath in @($startMenuLink, $startupLink)) {
    if (Test-Path $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath -Force
    }
}

if (Test-Path $installDirectory) {
    $quotedDirectory = '"' + $installDirectory + '"'
    $deleteCommand = "ping 127.0.0.1 -n 3 > nul & rmdir /s /q $quotedDirectory"
    Start-Process -FilePath $env:ComSpec -ArgumentList '/d', '/c', $deleteCommand -WindowStyle Hidden
}

Add-Type -AssemblyName System.Windows.Forms
[Windows.Forms.MessageBox]::Show(
    'KeyboardFixer was removed. If it is still visible near the clock, right-click it and choose Exit.',
    'KeyboardFixer uninstalled'
) | Out-Null
