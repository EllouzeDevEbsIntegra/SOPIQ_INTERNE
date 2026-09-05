@echo off
title PosCaisse - Sauvegarde
echo.
echo   Copie de securite de la base
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\poscaisse.ps1" -Action backup
echo.
echo   Code de sortie : %errorlevel%
pause
