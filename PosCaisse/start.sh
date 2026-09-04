#!/usr/bin/env bash
# Linux/macOS launcher (equivalent of START_POS.bat)
cd "$(dirname "$0")"
mkdir -p logs
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then docker compose up -d postgres; fi
( cd backend && if [ -f target/poscaisse-backend.jar ]; then java -jar target/poscaisse-backend.jar; else mvn -q spring-boot:run; fi ) > logs/backend.log 2>&1 &
echo $! > backend.pid
if [ -f frontend/dist/index.html ]; then URL=http://localhost:${POSCAISSE_PORT:-8080}; else ( cd frontend && [ -d node_modules ] || npm install --no-audit --no-fund; npm run dev ) > logs/frontend.log 2>&1 & echo $! > frontend.pid; URL=http://localhost:5173; fi
echo "PosCaisse démarre… logs dans ./logs — ouvrez $URL"
