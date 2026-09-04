@echo off
title PosCaisse - Redemarrage
rem =====================================================================
rem  Double-cliquez sur ce fichier : il n'y a rien d'autre a faire.
rem
rem  Ce .bat ne contient volontairement aucune logique. Toute la sequence
rem  (arret, git pull, base, compilation, demarrage) vit dans restart.ps1 :
rem  cmd.exe mal-interprete les blocs entre parentheses et les etiquettes
rem  des qu'un .bat grossit, et sort sans rien afficher.
rem =====================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restart.ps1" -Pause
if errorlevel 9009 pause
