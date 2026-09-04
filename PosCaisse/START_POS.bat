@echo off
setlocal enabledelayedexpansion
title PosCaisse - Lancement
cd /d "%~dp0"
echo ==========================================================
echo   PosCaisse - Caisse tactile (Vue 3 + Spring Boot + PostgreSQL)
echo ==========================================================

REM ---- Variables d'environnement (modifiez si besoin, voir .env.example) ----
if "%POSCAISSE_DB_HOST%"=="" set POSCAISSE_DB_HOST=localhost
if "%POSCAISSE_DB_PORT%"=="" set POSCAISSE_DB_PORT=5432
if "%POSCAISSE_DB_NAME%"=="" set POSCAISSE_DB_NAME=poscaisse
if "%POSCAISSE_DB_USER%"=="" set POSCAISSE_DB_USER=postgres
if "%POSCAISSE_DB_PASSWORD%"=="" set POSCAISSE_DB_PASSWORD=postgres
if "%POSCAISSE_PORT%"=="" set POSCAISSE_PORT=8080

REM ---- 1. PostgreSQL : Docker si disponible et demarre, sinon service local ----
set "USE_DOCKER=0"
where docker >nul 2>nul
if not errorlevel 1 (
  docker info >nul 2>nul
  if not errorlevel 1 set "USE_DOCKER=1"
)
if "!USE_DOCKER!"=="1" (
  echo [1/4] Demarrage de PostgreSQL via Docker...
  docker compose up -d postgres
) else (
  echo [1/4] PostgreSQL local sur %POSCAISSE_DB_HOST%:%POSCAISSE_DB_PORT%
  net start postgresql-x64-18 >nul 2>nul
  net start postgresql-x64-17 >nul 2>nul
  net start postgresql-x64-16 >nul 2>nul
  net start postgresql-x64-15 >nul 2>nul
)

REM ---- 2. Base de donnees : creee automatiquement si absente ----
echo [2/4] Verification de la base "%POSCAISSE_DB_NAME%"...
call :ensure_db

REM ---- 3. Backend Spring Boot ----
echo [3/4] Demarrage du backend (port %POSCAISSE_PORT%)...
if exist "backend\target\poscaisse-backend.jar" (
  start "PosCaisse Backend" cmd /k "cd /d "%~dp0backend" && java -jar target\poscaisse-backend.jar"
) else (
  start "PosCaisse Backend" cmd /k "cd /d "%~dp0backend" && mvn -q spring-boot:run"
)

REM ---- 4. Frontend ----
if exist "frontend\dist\index.html" (
  echo [4/4] Frontend deja construit : servi par le backend sur http://localhost:%POSCAISSE_PORT%
  set "POS_URL=http://localhost:%POSCAISSE_PORT%"
) else (
  echo [4/4] Demarrage du frontend Vite (port 5173)...
  if not exist "frontend\node_modules" (
    echo     Installation des dependances npm (premiere fois, quelques minutes)...
    pushd frontend && call npm install --no-audit --no-fund && popd
  )
  start "PosCaisse Frontend" cmd /k "cd /d "%~dp0frontend" && npm run dev"
  set "POS_URL=http://localhost:5173"
)

echo.
echo Attente du backend...
set /a tries=0
:wait
timeout /t 3 /nobreak >nul
curl -s http://localhost:%POSCAISSE_PORT%/actuator/health | find "UP" >nul
if not errorlevel 1 goto ready
set /a tries+=1
if !tries! lss 60 goto wait
echo Le backend ne repond pas : lisez la fenetre "PosCaisse Backend" (derniere ligne "Caused by").
echo   - "la base de donnees ... n'existe pas"  -^> lancez INIT_DB.bat
echo   - "password authentication failed"       -^> definissez POSCAISSE_DB_PASSWORD (voir .env.example)
echo   - "Connection refused"                   -^> PostgreSQL n'est pas demarre
goto end

:ready
echo Backend pret. Ouverture de !POS_URL!
start "" "!POS_URL!"
echo.
echo Comptes de demonstration :
echo   Admin    admin / admin123      PIN 9999
echo   Manager  manager / manager123  PIN 2222
echo   Caissier Ahmed PIN 1234 - Sami PIN 5678 - Mariem PIN 4321

:end
echo.
echo Pour arreter : STOP_POS.bat
pause
exit /b

REM ============================================================
REM  Localise psql, attend PostgreSQL, cree la base si absente.
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
  echo     psql introuvable : verification automatique impossible.
  echo     Si le backend signale que la base n'existe pas, creez-la avec pgAdmin ou :
  echo        "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U %POSCAISSE_DB_USER% -c "CREATE DATABASE %POSCAISSE_DB_NAME%;"
  exit /b 1
)
set "PGPASSWORD=%POSCAISSE_DB_PASSWORD%"
set "PGCLIENTENCODING=UTF8"
set /a dbtries=0
:db_wait
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -tAc "SELECT 1" >nul 2>nul
if not errorlevel 1 goto db_ready
set /a dbtries+=1
if !dbtries! geq 20 (
  echo     PostgreSQL ne repond pas ^(service arrete, port different ou mot de passe incorrect^).
  exit /b 1
)
timeout /t 2 /nobreak >nul
goto db_wait

:db_ready
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='%POSCAISSE_DB_NAME%'" 2>nul | findstr /b /c:"1" >nul
if not errorlevel 1 (
  echo     Base "%POSCAISSE_DB_NAME%" presente.
  exit /b 0
)
echo     Base absente : creation de "%POSCAISSE_DB_NAME%"...
"%PSQL%" -h %POSCAISSE_DB_HOST% -p %POSCAISSE_DB_PORT% -U %POSCAISSE_DB_USER% -d postgres -c "CREATE DATABASE %POSCAISSE_DB_NAME%;" >nul 2>nul
if errorlevel 1 (
  echo     Creation impossible ^(droits insuffisants ?^). Creez-la manuellement puis relancez.
  exit /b 1
)
echo     Base creee. Flyway construira le schema au demarrage du backend.
exit /b 0
