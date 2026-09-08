@echo off
title PosCaisse - Installation
echo.
echo   Premiere mise en route du poste
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\poscaisse.ps1" -Action install
echo.
echo   Code de sortie : %errorlevel%
pause
