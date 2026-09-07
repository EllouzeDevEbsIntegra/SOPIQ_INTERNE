@echo off
rem  Fins de ligne CRLF imposees par .gitattributes (exigence de cmd.exe).
title PosCaisse - Nettoyage des ventes
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0nettoyer-ventes.ps1"
echo.
echo Code de sortie : %errorlevel%
pause
