@echo off
title PosCaisse - Etat
echo.
echo   Etat du poste
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\poscaisse.ps1" -Action status
echo.
echo   Code de sortie : %errorlevel%
pause
