@echo off
title PosCaisse - Arret
cd /d "%~dp0"
echo Arret du backend et du frontend PosCaisse...
taskkill /FI "WINDOWTITLE eq PosCaisse Backend*" /T /F >nul 2>nul
taskkill /FI "WINDOWTITLE eq PosCaisse Frontend*" /T /F >nul 2>nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8080 " ^| findstr LISTENING') do taskkill /PID %%p /F >nul 2>nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":5173 " ^| findstr LISTENING') do taskkill /PID %%p /F >nul 2>nul
where docker >nul 2>nul && docker compose stop postgres >nul 2>nul
echo Termine.
pause
