@echo off
title PosCaisse - Demarrage
echo.
echo   Ouverture de la caisse
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\poscaisse.ps1" -Action start
echo.
echo   Code de sortie : %errorlevel%
pause
