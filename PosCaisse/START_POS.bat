@echo off
title PosCaisse - Lancement
rem =====================================================================
rem  Lance PosCaisse sans rien arreter. Si l'application repond deja,
rem  le navigateur s'ouvre simplement sur la caisse.
rem  Pour repartir de zero (arret + mise a jour + recompilation) :
rem  RESTART_POS.bat.
rem =====================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restart.ps1" -Mode start -Pause
if errorlevel 9009 pause
