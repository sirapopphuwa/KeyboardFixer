@echo off
start "KeyboardFixer" powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0KeyboardFixer.ps1" -ShowWindow
