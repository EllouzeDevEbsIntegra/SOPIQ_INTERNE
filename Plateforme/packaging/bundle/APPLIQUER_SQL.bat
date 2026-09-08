@echo off
rem  Fins de ligne CRLF imposees par .gitattributes (exigence de cmd.exe).
title PosCaisse - Appliquer un script SQL
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0outils\appliquer-sql.ps1"
echo.
echo Code de sortie : %errorlevel%
pause
