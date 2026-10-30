@echo off
title Mintzer marketing FTP upload
cd /d "%~dp0"

echo.
echo Running upload-marketing-ftp.ps1 via PowerShell...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0upload-marketing-ftp.ps1" %*

echo.
pause
