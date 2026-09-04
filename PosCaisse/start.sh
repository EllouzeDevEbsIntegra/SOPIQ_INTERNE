#!/usr/bin/env bash
# Linux/macOS launcher (equivalent of START_POS.bat)
cd "$(dirname "$0")"
mkdir -p logs
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then docker compose up -d postgres; fi

# Base de données : créée automatiquement si absente
DB_HOST=${POSCAISSE_DB_HOST:-localhost}; DB_PORT=${POSCAISSE_DB_PORT:-5432}
DB_NAME=${POSCAISSE_DB_NAME:-poscaisse}; DB_USER=${POSCAISSE_DB_USER:-postgres}
export PGPASSWORD=${POSCAISSE_DB_PASSWORD:-postgres}
if command -v psql >/dev/null; then
  for i in $(seq 1 20); do psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc 'SELECT 1' >/dev/null 2>&1 && break; sleep 2; done
  if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null | grep -q 1; then
    echo "Création de la base $DB_NAME…"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;" >/dev/null || echo "Création impossible : créez la base manuellement."
  fi
fi
( cd backend && if [ -f target/poscaisse-backend.jar ]; then java -jar target/poscaisse-backend.jar; else mvn -q spring-boot:run; fi ) > logs/backend.log 2>&1 &
echo $! > backend.pid
if [ -f frontend/dist/index.html ]; then URL=http://localhost:${POSCAISSE_PORT:-8080}; else ( cd frontend && [ -d node_modules ] || npm install --no-audit --no-fund; npm run dev ) > logs/frontend.log 2>&1 & echo $! > frontend.pid; URL=http://localhost:5173; fi
echo "PosCaisse démarre… logs dans ./logs — ouvrez $URL"
