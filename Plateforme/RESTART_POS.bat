@echo off
title PosCaisse - Redemarrage
rem =====================================================================
rem  Ce fichier ne contient volontairement AUCUNE logique : cmd.exe casse
rem  silencieusement sur les blocs entre parentheses et les etiquettes.
rem  Tout se passe dans le .ps1, execute par le PowerShell de Windows.
rem  La pause finale est ici pour qu'une erreur reste lisible a l'ecran
rem  meme si PowerShell s'arrete des la lecture du script.
rem =====================================================================
echo Redemarrage complet de PosCaisse (restart.ps1)...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restart.ps1"
echo.
echo Code de sortie : %errorlevel%
pause
