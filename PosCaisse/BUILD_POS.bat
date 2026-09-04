@echo off
title PosCaisse - Build production
cd /d "%~dp0"
echo [1/2] Build frontend (npm run build)...
pushd frontend
if not exist node_modules call npm install --no-audit --no-fund
call npm run build || (echo ECHEC build frontend & pause & exit /b 1)
popd
echo [2/2] Build backend (mvn package, tests unitaires inclus)...
pushd backend
call mvn -q -B package || (echo ECHEC build backend & pause & exit /b 1)
popd
echo.
echo Build termine : backend\target\poscaisse-backend.jar sert le frontend depuis frontend\dist.
echo Lancez START_POS.bat puis ouvrez http://localhost:8080
pause
