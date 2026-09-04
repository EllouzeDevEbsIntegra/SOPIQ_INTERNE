@echo off
setlocal enabledelayedexpansion
title PosCaisse - Preparation de la base de donnees
cd /d "%~dp0"

if "%POSCAISSE_DB_HOST%"=="" set POSCAISSE_DB_HOST=localhost
if "%POSCAISSE_DB_PORT%"=="" set POSCAISSE_DB_PORT=5432
if "%POSCAISSE_DB_NAME%"=="" set POSCAISSE_DB_NAME=poscaisse
if "%POSCAISSE_DB_USER%"=="" set POSCAISSE_DB_USER=postgres
if "%POSCAISSE_DB_PASSWORD%"=="" set POSCAISSE_DB_PASSWORD=postgres

call :ensure_db
if errorlevel 1 (
  echo.
  echo Echec de la preparation de la base. Creez-la manuellement :
  echo    psql -U %POSCAISSE_DB_USER% -c "CREATE DATABASE %POSCAISSE_DB_NAME%;"
) else (
  echo Base "%POSCAISSE_DB_NAME%" prete sur %POSCAISSE_DB_HOST%:%POSCAISSE_DB_PORT%.
)
pause
exit /b

REM ============================================================
REM  Localise psql, attend PostgreSQL, cree la base si absente.
REM  Retourne errorlevel 0 si la base est utilisable.
REM ============================================================
:ensure_db
set "PSQL="
for /f "delims=" %%P in ('where psql 2^>nul') do if not defined PSQL set "PSQL=%%P"
if not defined PSQL (
  for %%V in (18 17 16 15 14 13 12) do (
    if not defined PSQL if exist "C:\Program Files\PostgreSQL\%%V\bin\psql.exe" set "PSQL=C:\Program Files\PostgreSQL\%%V\bin\psql.exe"
  )
)
if not defined PSQL (
  echo     psql introuvable : impossible de verifier/creer la base automatiquement.
  echo     Si le backend signale "la base de donnees %POSCAISSE_DB_NAME% n'existe pas", creez-la avec pgAdmin
  echo     ou : "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U %POSCAISSE_DB_USER% -c "CREATE DATABASE %POSCAISSE_DB_NAME%;"
  exit /b 1
)
set "PGPASSWORD=%POSCAISSE_DB_PASSWORD%"
set "PGCLIENTENCODING=UTF8"

echo     Attente de PostgreSQL sur %POSCAISSE_DB_HOST%:%POSCAISSE_DB_PORT%...
set /a dbtries=0
:db_wait
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -tAc "SELECT 1" >nul 2>nul
if not errorlevel 1 goto db_ready
set /a dbtries+=1
if %dbtries% geq 20 (
  echo     PostgreSQL ne repond pas ^(service arrete, port different ou mot de passe incorrect^).
  echo     Verifiez POSCAISSE_DB_USER / POSCAISSE_DB_PASSWORD ^(voir .env.example^).
  exit /b 1
)
timeout /t 2 /nobreak >nul
goto db_wait

:db_ready
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='%POSCAISSE_DB_NAME%'" 2>nul | findstr /b /c:"1" >nul
if not errorlevel 1 (
  echo     Base "%POSCAISSE_DB_NAME%" deja presente.
  exit /b 0
)
echo     Creation de la base "%POSCAISSE_DB_NAME%"...
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -c "CREATE DATABASE %POSCAISSE_DB_NAME%;" >nul 2>nul
if errorlevel 1 (
  echo     Creation impossible ^(droits insuffisants pour %POSCAISSE_DB_USER% ?^).
  exit /b 1
)
echo     Base creee. Flyway construira le schema au demarrage du backend.
exit /b 0
