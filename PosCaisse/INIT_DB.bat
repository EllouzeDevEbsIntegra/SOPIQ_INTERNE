@echo off
setlocal
title PosCaisse - Preparation de la base de donnees
cd /d "%~dp0"

call "%~dp0_ensure_db.bat"
if errorlevel 1 (
  echo.
  echo Echec de la preparation de la base. Creez-la manuellement :
  echo    psql -U %POSCAISSE_DB_USER% -c "CREATE DATABASE %POSCAISSE_DB_NAME%;"
)
echo.
pause
endlocal
