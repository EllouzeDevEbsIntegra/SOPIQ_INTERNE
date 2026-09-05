@echo off
title PosCaisse - Export des donnees
echo.
echo   Export des donnees de ce poste vers un fichier transferable
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0exporter-donnees.ps1"
echo.
echo   Code de sortie : %errorlevel%
pause
