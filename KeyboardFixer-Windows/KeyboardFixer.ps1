param([switch]$ShowWindow)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
    throw 'KeyboardFixer must run in STA mode. Start it with Start KeyboardFixer.bat.'
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. (Join-Path $PSScriptRoot 'KeyboardFixer.Core.ps1')

Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public sealed class KeyboardFixerHotKeyEventArgs : EventArgs
{
    public int Id { get; private set; }
    public KeyboardFixerHotKeyEventArgs(int id) { Id = id; }
}

public sealed class KeyboardFixerHotKeyWindow : NativeWindow, IDisposable
{
    private const int WM_HOTKEY = 0x0312;
    private const uint MOD_CONTROL = 0x0002;
    private const uint MOD_SHIFT = 0x0004;
    private const uint ClipboardHotKey = 0x56;
    private const uint SelectionHotKey = 0x58;

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint virtualKey);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    public event EventHandler<KeyboardFixerHotKeyEventArgs> HotKeyPressed;

    public KeyboardFixerHotKeyWindow()
    {
        CreateHandle(new CreateParams());
    }

    public bool RegisterClipboardHotKey() { return RegisterHotKey(Handle, 1, MOD_CONTROL | MOD_SHIFT, ClipboardHotKey); }
    public bool RegisterSelectionHotKey() { return RegisterHotKey(Handle, 2, MOD_CONTROL | MOD_SHIFT, SelectionHotKey); }

    protected override void WndProc(ref Message message)
    {
        if (message.Msg == WM_HOTKEY && HotKeyPressed != null)
            HotKeyPressed(this, new KeyboardFixerHotKeyEventArgs(message.WParam.ToInt32()));
        base.WndProc(ref message);
    }

    public void Dispose()
    {
        UnregisterHotKey(Handle, 1);
        UnregisterHotKey(Handle, 2);
        DestroyHandle();
    }
}

public static class KeyboardFixerKeySender
{
    private const byte VK_CONTROL = 0x11;
    private const uint KEYEVENTF_KEYUP = 0x0002;

    [DllImport("user32.dll")]
    private static extern void keybd_event(byte virtualKey, byte scanCode, uint flags, UIntPtr extraInfo);

    public static void SendControlKey(byte virtualKey)
    {
        keybd_event(VK_CONTROL, 0, 0, UIntPtr.Zero);
        keybd_event(virtualKey, 0, 0, UIntPtr.Zero);
        keybd_event(virtualKey, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
    }
}
'@

$applicationName = 'KeyboardFixer'
$createdNew = $false
$mutex = New-Object Threading.Mutex($true, 'Local\KeyboardFixer.Windows.Singleton', [ref]$createdNew)
if (-not $createdNew) {
    [Windows.Forms.MessageBox]::Show('KeyboardFixer is already running in the system tray.', $applicationName) | Out-Null
    exit 0
}

$configDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'KeyboardFixer'
$configPath = Join-Path $configDirectory 'settings.json'
$startupLinkPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'KeyboardFixer.lnk'

$settings = [ordered]@{
    Mode = 'Auto'
    AutoCopy = $true
    ClipboardHotKey = $true
    SelectionHotKey = $true
    LaunchAtStartup = $true
}

if (Test-Path $configPath) {
    try {
        $savedSettings = Get-Content -Raw -Path $configPath | ConvertFrom-Json
        foreach ($key in @($settings.Keys)) {
            if ($null -ne $savedSettings.$key) { $settings[$key] = $savedSettings.$key }
        }
    } catch {
        # Invalid settings are ignored and replaced by safe defaults when saved.
    }
}

function Save-KeyboardFixerSettings {
    if (-not (Test-Path $configDirectory)) {
        New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
    }
    $settings | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
}

function Set-KeyboardFixerStartup {
    param([bool]$Enabled)

    if ($Enabled) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($startupLinkPath)
        $shortcut.TargetPath = (Join-Path $PSHOME 'powershell.exe')
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
        $shortcut.WorkingDirectory = $PSScriptRoot
        $shortcut.Description = 'Start KeyboardFixer at login'
        $shortcut.Save()
    } elseif (Test-Path $startupLinkPath) {
        Remove-Item -Path $startupLinkPath -Force
    }
}

function Get-ClipboardTextWithRetry {
    for ($attempt = 0; $attempt -lt 8; $attempt++) {
        try {
            if ([Windows.Forms.Clipboard]::ContainsText()) {
                return [Windows.Forms.Clipboard]::GetText()
            }
            return $null
        } catch [Runtime.InteropServices.ExternalException] {
            Start-Sleep -Milliseconds 35
        }
    }
    return $null
}

function Set-ClipboardTextWithRetry {
    param([Parameter(Mandatory = $true)][string]$Text)

    for ($attempt = 0; $attempt -lt 8; $attempt++) {
        try {
            [Windows.Forms.Clipboard]::SetText($Text)
            return $true
        } catch [Runtime.InteropServices.ExternalException] {
            Start-Sleep -Milliseconds 35
        }
    }
    return $false
}

$notifyIcon = New-Object Windows.Forms.NotifyIcon
$notifyIcon.Icon = [Drawing.SystemIcons]::Application
$notifyIcon.Text = 'KeyboardFixer'
$notifyIcon.Visible = $true

function Show-KeyboardFixerStatus {
    param([string]$Message, [Windows.Forms.ToolTipIcon]$Icon = [Windows.Forms.ToolTipIcon]::Info)
    $notifyIcon.BalloonTipTitle = 'KeyboardFixer'
    $notifyIcon.BalloonTipText = $Message
    $notifyIcon.BalloonTipIcon = $Icon
    $notifyIcon.ShowBalloonTip(1200)
}

function Convert-KeyboardFixerClipboard {
    $text = Get-ClipboardTextWithRetry
    if ([string]::IsNullOrEmpty($text)) {
        Show-KeyboardFixerStatus 'Clipboard has no plain text.' ([Windows.Forms.ToolTipIcon]::Warning)
        return
    }

    $result = Invoke-KeyboardFixerConversion -Text $text -Mode $settings.Mode
    if (-not $result.Converted) {
        Show-KeyboardFixerStatus 'Direction is uncertain. Choose a direction from the tray window.' ([Windows.Forms.ToolTipIcon]::Warning)
        return
    }

    if (Set-ClipboardTextWithRetry -Text $result.Text) {
        Show-KeyboardFixerStatus 'Clipboard converted.'
    } else {
        Show-KeyboardFixerStatus 'Could not write to the clipboard.' ([Windows.Forms.ToolTipIcon]::Error)
    }
}

function Restore-KeyboardFixerClipboard {
    param($DataObject)
    if ($null -eq $DataObject) { return }

    for ($attempt = 0; $attempt -lt 8; $attempt++) {
        try {
            [Windows.Forms.Clipboard]::SetDataObject($DataObject, $true)
            return
        } catch [Runtime.InteropServices.ExternalException] {
            Start-Sleep -Milliseconds 35
        }
    }
}

function Convert-KeyboardFixerSelection {
    try { $originalClipboard = [Windows.Forms.Clipboard]::GetDataObject() } catch { $originalClipboard = $null }
    $marker = 'KeyboardFixer.Selection.' + [Guid]::NewGuid().ToString('N')
    if (-not (Set-ClipboardTextWithRetry -Text $marker)) {
        Show-KeyboardFixerStatus 'Could not prepare the clipboard.' ([Windows.Forms.ToolTipIcon]::Error)
        return
    }

    # Let the physical hotkey modifiers return to the up state before Ctrl+C.
    Start-Sleep -Milliseconds 180
    [KeyboardFixerKeySender]::SendControlKey(0x43)

    $selectedText = $null
    for ($attempt = 0; $attempt -lt 16; $attempt++) {
        Start-Sleep -Milliseconds 40
        $candidate = Get-ClipboardTextWithRetry
        if ($null -ne $candidate -and $candidate -ne $marker) {
            $selectedText = $candidate
            break
        }
    }

    if ([string]::IsNullOrEmpty($selectedText)) {
        Restore-KeyboardFixerClipboard $originalClipboard
        Show-KeyboardFixerStatus 'Select editable text, then press Ctrl+Shift+X.' ([Windows.Forms.ToolTipIcon]::Warning)
        return
    }

    $result = Invoke-KeyboardFixerConversion -Text $selectedText -Mode $settings.Mode
    if (-not $result.Converted -or $result.Text -eq $selectedText) {
        Restore-KeyboardFixerClipboard $originalClipboard
        Show-KeyboardFixerStatus 'No confident conversion was found.' ([Windows.Forms.ToolTipIcon]::Warning)
        return
    }

    if (-not (Set-ClipboardTextWithRetry -Text $result.Text)) {
        Restore-KeyboardFixerClipboard $originalClipboard
        Show-KeyboardFixerStatus 'Could not prepare the corrected text.' ([Windows.Forms.ToolTipIcon]::Error)
        return
    }

    Start-Sleep -Milliseconds 70
    [KeyboardFixerKeySender]::SendControlKey(0x56)
    Start-Sleep -Milliseconds 350
    Restore-KeyboardFixerClipboard $originalClipboard
    Show-KeyboardFixerStatus 'Selection fixed.'
}

$form = New-Object Windows.Forms.Form
$form.Text = 'KeyboardFixer'
$form.Size = New-Object Drawing.Size(430, 610)
$form.MinimumSize = New-Object Drawing.Size(430, 610)
$form.StartPosition = 'CenterScreen'
$form.ShowInTaskbar = $false
$form.Font = New-Object Drawing.Font('Segoe UI', 9)

$titleLabel = New-Object Windows.Forms.Label
$titleLabel.Text = 'KeyboardFixer'
$titleLabel.Font = New-Object Drawing.Font('Segoe UI Semibold', 16)
$titleLabel.Location = New-Object Drawing.Point(18, 16)
$titleLabel.AutoSize = $true
$form.Controls.Add($titleLabel)

$modeBox = New-Object Windows.Forms.ComboBox
$modeBox.DropDownStyle = 'DropDownList'
[void]$modeBox.Items.Add('Auto')
[void]$modeBox.Items.Add('English to Thai')
[void]$modeBox.Items.Add('Thai to English')
$modeBox.Location = New-Object Drawing.Point(20, 56)
$modeBox.Size = New-Object Drawing.Size(370, 28)
$form.Controls.Add($modeBox)

$inputLabel = New-Object Windows.Forms.Label
$inputLabel.Text = 'Input'
$inputLabel.Location = New-Object Drawing.Point(18, 96)
$inputLabel.AutoSize = $true
$form.Controls.Add($inputLabel)

$inputBox = New-Object Windows.Forms.TextBox
$inputBox.Multiline = $true
$inputBox.ScrollBars = 'Vertical'
$inputBox.Location = New-Object Drawing.Point(20, 118)
$inputBox.Size = New-Object Drawing.Size(370, 120)
$form.Controls.Add($inputBox)

$outputLabel = New-Object Windows.Forms.Label
$outputLabel.Text = 'Output'
$outputLabel.Location = New-Object Drawing.Point(18, 252)
$outputLabel.AutoSize = $true
$form.Controls.Add($outputLabel)

$outputBox = New-Object Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = 'Vertical'
$outputBox.Location = New-Object Drawing.Point(20, 274)
$outputBox.Size = New-Object Drawing.Size(370, 120)
$form.Controls.Add($outputBox)

$pasteButton = New-Object Windows.Forms.Button
$pasteButton.Text = 'Paste && Convert'
$pasteButton.Location = New-Object Drawing.Point(20, 410)
$pasteButton.Size = New-Object Drawing.Size(140, 32)
$form.Controls.Add($pasteButton)

$copyButton = New-Object Windows.Forms.Button
$copyButton.Text = 'Copy Result'
$copyButton.Location = New-Object Drawing.Point(170, 410)
$copyButton.Size = New-Object Drawing.Size(105, 32)
$form.Controls.Add($copyButton)

$clearButton = New-Object Windows.Forms.Button
$clearButton.Text = 'Clear'
$clearButton.Location = New-Object Drawing.Point(285, 410)
$clearButton.Size = New-Object Drawing.Size(105, 32)
$form.Controls.Add($clearButton)

$autoCopyCheckBox = New-Object Windows.Forms.CheckBox
$autoCopyCheckBox.Text = 'Copy result automatically'
$autoCopyCheckBox.Location = New-Object Drawing.Point(20, 460)
$autoCopyCheckBox.AutoSize = $true
$form.Controls.Add($autoCopyCheckBox)

$startupCheckBox = New-Object Windows.Forms.CheckBox
$startupCheckBox.Text = 'Launch at startup'
$startupCheckBox.Location = New-Object Drawing.Point(220, 460)
$startupCheckBox.AutoSize = $true
$form.Controls.Add($startupCheckBox)

$shortcutLabel = New-Object Windows.Forms.Label
$shortcutLabel.Text = "Ctrl+Shift+V  Convert clipboard`r`nCtrl+Shift+X  Replace selected text"
$shortcutLabel.Location = New-Object Drawing.Point(20, 500)
$shortcutLabel.Size = New-Object Drawing.Size(370, 48)
$shortcutLabel.ForeColor = [Drawing.SystemColors]::GrayText
$form.Controls.Add($shortcutLabel)

function Get-SelectedMode {
    switch ($modeBox.SelectedIndex) {
        1 { return 'EnglishToThai' }
        2 { return 'ThaiToEnglish' }
        default { return 'Auto' }
    }
}

function Update-KeyboardFixerOutput {
    $settings.Mode = Get-SelectedMode
    $result = Invoke-KeyboardFixerConversion -Text $inputBox.Text -Mode $settings.Mode
    $outputBox.Text = $result.Text
}

switch ($settings.Mode) {
    'EnglishToThai' { $modeBox.SelectedIndex = 1 }
    'ThaiToEnglish' { $modeBox.SelectedIndex = 2 }
    default { $modeBox.SelectedIndex = 0 }
}
$autoCopyCheckBox.Checked = [bool]$settings.AutoCopy
$startupCheckBox.Checked = [bool]$settings.LaunchAtStartup

$modeBox.add_SelectedIndexChanged({
    $settings.Mode = Get-SelectedMode
    Save-KeyboardFixerSettings
    Update-KeyboardFixerOutput
})
$inputBox.add_TextChanged({ Update-KeyboardFixerOutput })
$autoCopyCheckBox.add_CheckedChanged({
    $settings.AutoCopy = $autoCopyCheckBox.Checked
    Save-KeyboardFixerSettings
})
$startupCheckBox.add_CheckedChanged({
    $settings.LaunchAtStartup = $startupCheckBox.Checked
    Set-KeyboardFixerStartup -Enabled $startupCheckBox.Checked
    Save-KeyboardFixerSettings
})
$pasteButton.add_Click({
    $text = Get-ClipboardTextWithRetry
    if ($null -eq $text) { return }
    $inputBox.Text = $text
    Update-KeyboardFixerOutput
    if ($settings.AutoCopy -and -not [string]::IsNullOrEmpty($outputBox.Text)) {
        [Windows.Forms.Clipboard]::SetText($outputBox.Text)
    }
})
$copyButton.add_Click({
    if (-not [string]::IsNullOrEmpty($outputBox.Text)) {
        [Windows.Forms.Clipboard]::SetText($outputBox.Text)
        Show-KeyboardFixerStatus 'Copied.'
    }
})
$clearButton.add_Click({ $inputBox.Clear(); $outputBox.Clear() })

$script:AllowExit = $false
$form.add_FormClosing({
    param($sender, $eventArgs)
    if (-not $script:AllowExit) {
        $eventArgs.Cancel = $true
        $form.Hide()
    }
})

$contextMenu = New-Object Windows.Forms.ContextMenuStrip
$openItem = $contextMenu.Items.Add('Open KeyboardFixer')
$convertItem = $contextMenu.Items.Add('Convert Clipboard    Ctrl+Shift+V')
[void]$contextMenu.Items.Add('-')
$exitItem = $contextMenu.Items.Add('Exit')
$notifyIcon.ContextMenuStrip = $contextMenu

$showForm = {
    $form.Show()
    $form.WindowState = 'Normal'
    $form.Activate()
}
$openItem.add_Click($showForm)
$notifyIcon.add_DoubleClick($showForm)
$convertItem.add_Click({ Convert-KeyboardFixerClipboard })
$exitItem.add_Click({
    $script:AllowExit = $true
    $notifyIcon.Visible = $false
    [Windows.Forms.Application]::ExitThread()
})

$hotKeyWindow = New-Object KeyboardFixerHotKeyWindow
$clipboardHotKeyRegistered = $hotKeyWindow.RegisterClipboardHotKey()
$selectionHotKeyRegistered = $hotKeyWindow.RegisterSelectionHotKey()
$hotKeyWindow.add_HotKeyPressed({
    param($sender, $eventArgs)
    if ($eventArgs.Id -eq 1) { Convert-KeyboardFixerClipboard }
    if ($eventArgs.Id -eq 2) { Convert-KeyboardFixerSelection }
})

if (-not $clipboardHotKeyRegistered -or -not $selectionHotKeyRegistered) {
    Show-KeyboardFixerStatus 'One or more shortcuts are already used by another app.' ([Windows.Forms.ToolTipIcon]::Warning)
}

Save-KeyboardFixerSettings
Set-KeyboardFixerStartup -Enabled ([bool]$settings.LaunchAtStartup)

if ($ShowWindow) { & $showForm }

try {
    [Windows.Forms.Application]::Run()
} finally {
    $hotKeyWindow.Dispose()
    $notifyIcon.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
