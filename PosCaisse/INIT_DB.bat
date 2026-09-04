@echo off
title PosCaisse - Preparation de la base de donnees
rem =====================================================================
rem  Demarre PostgreSQL et cree la base "poscaisse" si elle n'existe pas.
rem  La logique est dans init-db.ps1.
rem =====================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init-db.ps1"
echo.
pause
