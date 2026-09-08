@echo off
rem =====================================================================
rem  Compatibilite : ce fichier ne fait plus que rediriger vers
rem  init-db.ps1, seule implementation de la preparation de la base.
rem  errorlevel 0 = base utilisable.
rem =====================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init-db.ps1"
exit /b %errorlevel%
