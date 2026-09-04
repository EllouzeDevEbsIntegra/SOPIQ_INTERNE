@echo off
REM =====================================================================
REM  PosCaisse — tout en un : arret, mise a jour, base, build, demarrage.
REM  Double-cliquez sur ce fichier : il n'y a rien d'autre a faire.
REM =====================================================================

REM --- git pull peut reecrire ce script pendant son execution (cmd.exe lit
REM     les .bat au fil de l'eau) : on s'execute depuis une copie temporaire.
if /i not "%~1"=="--copie" (
  copy /y "%~f0" "%TEMP%\poscaisse-restart.bat" >nul
  call "%TEMP%\poscaisse-restart.bat" --copie "%~dp0."
  exit /b
)

setlocal enabledelayedexpansion
title PosCaisse - Redemarrage
set "ROOT=%~2"
cd /d "%ROOT%"

echo ==========================================================
echo   PosCaisse - redemarrage complet
echo ==========================================================

if "%POSCAISSE_DB_HOST%"=="" set POSCAISSE_DB_HOST=localhost
if "%POSCAISSE_DB_PORT%"=="" set POSCAISSE_DB_PORT=5432
if "%POSCAISSE_DB_NAME%"=="" set POSCAISSE_DB_NAME=poscaisse
if "%POSCAISSE_DB_USER%"=="" set POSCAISSE_DB_USER=postgres
if "%POSCAISSE_DB_PASSWORD%"=="" set POSCAISSE_DB_PASSWORD=postgres
if "%POSCAISSE_PORT%"=="" set POSCAISSE_PORT=8080

REM ---------------------------------------------------------- 1. arret
echo.
echo [1/6] Arret des instances en cours...
taskkill /FI "WINDOWTITLE eq PosCaisse Backend*" /T /F >nul 2>nul
taskkill /FI "WINDOWTITLE eq PosCaisse Frontend*" /T /F >nul 2>nul
call :kill_port %POSCAISSE_PORT%
call :kill_port 5173
echo     Ports %POSCAISSE_PORT% et 5173 liberes.

REM ---------------------------------------------------- 2. mise a jour
echo.
echo [2/6] Mise a jour du code...
set "REBUILD=0"
set "BEFORE="
set "AFTER="
where git >nul 2>nul
if errorlevel 1 (
  echo     git absent : etape ignoree.
) else (
  git rev-parse --is-inside-work-tree >nul 2>nul
  if errorlevel 1 (
    echo     Dossier hors depot git : etape ignoree.
  ) else (
    for /f "delims=" %%h in ('git rev-parse HEAD 2^>nul') do set "BEFORE=%%h"
    git pull --ff-only
    if errorlevel 1 echo     git pull a echoue ^(modifications locales ou reseau^) : on continue avec le code present.
    for /f "delims=" %%h in ('git rev-parse HEAD 2^>nul') do set "AFTER=%%h"
    if "!BEFORE!"=="!AFTER!" (
      echo     Deja a jour.
    ) else (
      echo     Nouvelle version recuperee.
      set "REBUILD=1"
    )
  )
)

REM ------------------------------------------------------ 3. PostgreSQL
echo.
echo [3/6] PostgreSQL et base de donnees...
set "USE_DOCKER=0"
where docker >nul 2>nul
if not errorlevel 1 (
  docker info >nul 2>nul
  if not errorlevel 1 set "USE_DOCKER=1"
)
if "!USE_DOCKER!"=="1" (
  docker compose up -d postgres >nul 2>nul
  echo     PostgreSQL demarre via Docker.
) else (
  net start postgresql-x64-18 >nul 2>nul
  net start postgresql-x64-17 >nul 2>nul
  net start postgresql-x64-16 >nul 2>nul
  net start postgresql-x64-15 >nul 2>nul
)
call "%ROOT%\_ensure_db.bat"

REM ------------------------------------------------------ 4. compilation
echo.
if not exist "frontend\dist\index.html" set "REBUILD=1"
if not exist "backend\target\poscaisse-backend.jar" set "REBUILD=1"
set "BUILD_OK=1"
if "!REBUILD!"=="0" (
  echo [4/6] Aucun changement : compilation inutile.
) else (
  echo [4/6] Compilation ^(cela peut prendre 1 a 2 minutes^)...
  call :build
)
if not "!BUILD_OK!"=="1" goto :fail

REM ------------------------------------------------------ 5. demarrage
echo.
echo [5/6] Demarrage du backend sur le port %POSCAISSE_PORT%...
if exist "backend\target\poscaisse-backend.jar" (
  start "PosCaisse Backend" cmd /k "cd /d "%ROOT%\backend" && java -jar target\poscaisse-backend.jar"
) else (
  start "PosCaisse Backend" cmd /k "cd /d "%ROOT%\backend" && mvn -q spring-boot:run"
)

REM --------------------------------------------------------- 6. attente
echo.
echo [6/6] Attente du demarrage...
set /a tries=0
:wait_health
timeout /t 3 /nobreak >nul
curl -s http://localhost:%POSCAISSE_PORT%/actuator/health | find "UP" >nul
if not errorlevel 1 goto ready
set /a tries+=1
if !tries! lss 60 goto wait_health
echo.
echo     Le backend ne repond pas. Lisez la fenetre "PosCaisse Backend",
echo     derniere ligne commencant par "Caused by".
goto :end

:ready
echo     Backend pret.
start "" "http://localhost:%POSCAISSE_PORT%"
echo.
echo ==========================================================
echo   PosCaisse est lance : http://localhost:%POSCAISSE_PORT%
echo ==========================================================
echo.
echo   Admin    admin / admin123      PIN 9999
echo   Manager  manager / manager123  PIN 2222
echo   Caissier Ahmed 1234 - Sami 5678 - Mariem 4321
echo.
echo   Cette fenetre peut etre fermee. Pour arreter : STOP_POS.bat
goto :end

:fail
echo.
echo   Redemarrage interrompu.

:end
echo.
pause
endlocal
exit /b

REM ============================================================
REM  Construction : interface Vue puis jar Spring Boot.
REM  Positionne BUILD_OK=0 en cas d'echec bloquant.
REM ============================================================
:build
where npm >nul 2>nul
if errorlevel 1 (
  echo     npm introuvable : l'interface ne peut pas etre compilee.
  echo     Installez Node.js depuis https://nodejs.org puis relancez ce script.
) else (
  pushd frontend
  if not exist node_modules (
    echo     Installation des dependances npm...
    call npm install --no-audit --no-fund
  )
  echo     Construction de l'interface...
  call npm run build
  popd
)
where mvn >nul 2>nul
if errorlevel 1 (
  echo     Maven introuvable : impossible de construire le backend.
  set "BUILD_OK=0"
  exit /b 1
)
pushd backend
echo     Construction du backend...
call mvn -q -B package -DskipTests
if errorlevel 1 set "BUILD_OK=0"
popd
if not "!BUILD_OK!"=="1" echo     ECHEC de la construction du backend.
exit /b 0

REM ============================================================
REM  Termine le processus qui ecoute sur le port passe en %1
REM ============================================================
:kill_port
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%~1 " ^| findstr LISTENING') do (
  taskkill /PID %%p /T /F >nul 2>nul
)
exit /b 0
