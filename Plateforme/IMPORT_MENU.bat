@echo off
rem  Fins de ligne CRLF imposees par .gitattributes (exigence de cmd.exe).
setlocal
title PosCaisse - Import de la carte
cd /d "%~dp0"
echo ==========================================================
echo   Import de la carte dans PosCaisse
echo ==========================================================
echo.
echo   Fichier : catalogs\number-one.json
echo.
echo   ATTENTION : le catalogue actuel sera remplace.
echo   Les articles jamais vendus sont supprimes ; ceux deja
echo   vendus sont conserves mais desactives, pour que
echo   l'historique des tickets reste intact.
echo.
choice /c ON /n /m "  Continuer ? [O]ui / [N]on : "
if errorlevel 2 goto :fin
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0import-menu.ps1"
:fin
echo.
pause
endlocal
