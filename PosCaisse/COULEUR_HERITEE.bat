@echo off
rem Remet chaque article a la couleur de sa rubrique.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0catalogs\couleur-heritee.ps1" %*
pause
