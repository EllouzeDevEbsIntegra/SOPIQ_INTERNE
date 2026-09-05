@echo off
rem  Fins de ligne CRLF imposees par .gitattributes (exigence de cmd.exe).
title PosCaisse - Raccourcis
echo.
echo   Raccourcis de la caisse
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\poscaisse.ps1" -Action raccourcis
echo.
echo   Code de sortie : %errorlevel%
pause
