@echo off
setlocal
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

REM ---- 1. PostgreSQL : Docker si disponible, sinon service local ----
where docker >nul 2>nul
if %errorlevel%==0 (
  docker info >nul 2>nul
  if %errorlevel%==0 (
    echo [1/3] Demarrage de PostgreSQL via Docker...
    docker compose up -d postgres
  ) else (
    echo [1/3] Docker present mais non demarre : utilisation du PostgreSQL local sur %POSCAISSE_DB_HOST%:%POSCAISSE_DB_PORT%
  )
) else (
  echo [1/3] Docker absent : utilisation du PostgreSQL local sur %POSCAISSE_DB_HOST%:%POSCAISSE_DB_PORT%
  net start postgresql-x64-16 >nul 2>nul
)

REM ---- 2. Backend Spring Boot ----
echo [2/3] Demarrage du backend (port %POSCAISSE_PORT%)...
if exist "backend\target\poscaisse-backend.jar" (
  start "PosCaisse Backend" cmd /k "cd /d "%~dp0backend" && java -jar target\poscaisse-backend.jar"
) else (
  start "PosCaisse Backend" cmd /k "cd /d "%~dp0backend" && mvn -q spring-boot:run"
)

REM ---- 3. Frontend ----
if exist "frontend\dist\index.html" (
  echo [3/3] Frontend deja construit : il est servi par le backend sur http://localhost:%POSCAISSE_PORT%
  set POS_URL=http://localhost:%POSCAISSE_PORT%
) else (
  echo [3/3] Demarrage du frontend Vite (port 5173)...
  if not exist "frontend\node_modules" (
    echo     Installation des dependances npm (premiere fois)...
    pushd frontend && call npm install --no-audit --no-fund && popd
  )
  start "PosCaisse Frontend" cmd /k "cd /d "%~dp0frontend" && npm run dev"
  set POS_URL=http://localhost:5173
)

echo.
echo Attente du backend...
set /a tries=0
:wait
timeout /t 3 /nobreak >nul
curl -s http://localhost:%POSCAISSE_PORT%/actuator/health | find "UP" >nul
if %errorlevel%==0 goto ready
set /a tries+=1
if %tries% lss 40 goto wait
echo Le backend ne repond pas encore : verifiez la fenetre "PosCaisse Backend" (PostgreSQL demarre ? identifiants corrects ?)
goto end
:ready
echo Backend pret. Ouverture de %POS_URL%
start "" %POS_URL%
echo.
echo Comptes de demonstration : admin / admin123 (PIN 9999) - manager / manager123 (PIN 2222) - caissiers PIN 1234 (Ahmed), 5678 (Sami), 4321 (Mariem)
:end
echo.
echo Pour arreter : STOP_POS.bat
pause
endlocal
