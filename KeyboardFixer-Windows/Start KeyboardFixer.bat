@echo off
start "KeyboardFixer" powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0KeyboardFixer.ps1"
