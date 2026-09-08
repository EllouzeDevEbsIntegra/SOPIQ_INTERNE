@echo off
rem Exporte la carte de la caisse vers site\carte-live.json, pour construire le site.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0site\outils\exporter-carte.ps1" %*
pause
