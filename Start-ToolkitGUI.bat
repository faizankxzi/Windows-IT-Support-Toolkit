@echo off
cd /d "%~dp0"
start "" powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0src\Start-ToolkitGUI.ps1"
exit /b %errorlevel%
