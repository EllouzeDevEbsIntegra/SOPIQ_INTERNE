@echo off
title PosCaisse - Arret
echo.
echo   Arret de la caisse et de la base
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\poscaisse.ps1" -Action stop
echo.
echo   Code de sortie : %errorlevel%
pause
