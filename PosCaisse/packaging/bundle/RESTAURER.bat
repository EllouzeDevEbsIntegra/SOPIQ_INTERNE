@echo off
title PosCaisse - Restauration
echo.
echo   Restauration d une sauvegarde (REMPLACE les donnees actuelles)
echo.
set /p f=  Chemin du fichier .dump : 
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\poscaisse.ps1" -Action restore -Fichier "%f%"
echo.
pause
