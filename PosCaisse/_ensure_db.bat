@echo off
REM ============================================================
REM  Routine partagee : localise psql, attend PostgreSQL,
REM  cree la base si elle n'existe pas.
REM  Appelee par INIT_DB.bat, START_POS.bat et RESTART_POS.bat.
REM  Sortie : errorlevel 0 si la base est utilisable.
REM ============================================================
setlocal enabledelayedexpansion

if "%POSCAISSE_DB_HOST%"=="" set POSCAISSE_DB_HOST=localhost
if "%POSCAISSE_DB_PORT%"=="" set POSCAISSE_DB_PORT=5432
if "%POSCAISSE_DB_NAME%"=="" set POSCAISSE_DB_NAME=poscaisse
if "%POSCAISSE_DB_USER%"=="" set POSCAISSE_DB_USER=postgres
if "%POSCAISSE_DB_PASSWORD%"=="" set POSCAISSE_DB_PASSWORD=postgres

set "PSQL="
for /f "delims=" %%P in ('where psql 2^>nul') do if not defined PSQL set "PSQL=%%P"
if not defined PSQL (
  for %%V in (18 17 16 15 14 13 12) do (
    if not defined PSQL if exist "C:\Program Files\PostgreSQL\%%V\bin\psql.exe" set "PSQL=C:\Program Files\PostgreSQL\%%V\bin\psql.exe"
  )
)
if not defined PSQL (
  echo     psql introuvable : verification automatique impossible.
  echo     Si le backend signale que la base n'existe pas, creez-la avec pgAdmin ou :
  echo        "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U %POSCAISSE_DB_USER% -c "CREATE DATABASE %POSCAISSE_DB_NAME%;"
  endlocal & exit /b 1
)

set "PGPASSWORD=%POSCAISSE_DB_PASSWORD%"
set "PGCLIENTENCODING=UTF8"
set /a tries=0
:wait
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -tAc "SELECT 1" >nul 2>nul
if not errorlevel 1 goto ready
set /a tries+=1
if !tries! geq 20 (
  echo     PostgreSQL ne repond pas ^(service arrete, port different ou mot de passe incorrect^).
  endlocal & exit /b 1
)
timeout /t 2 /nobreak >nul
goto wait

:ready
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='%POSCAISSE_DB_NAME%'" 2>nul | findstr /b /c:"1" >nul
if not errorlevel 1 (
  echo     Base "%POSCAISSE_DB_NAME%" prete.
  endlocal & exit /b 0
)
echo     Base absente : creation de "%POSCAISSE_DB_NAME%"...
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -c "CREATE DATABASE %POSCAISSE_DB_NAME%;" >nul 2>nul
if errorlevel 1 (
  echo     Creation impossible ^(droits insuffisants ?^). Creez-la manuellement puis relancez.
  endlocal & exit /b 1
)
echo     Base creee. Flyway construira le schema au demarrage.
endlocal & exit /b 0
