#!/usr/bin/env bash
# =====================================================================
#  PosCaisse — tout en un : arrêt, mise à jour, base, build, démarrage.
#  Équivalent Linux/macOS de RESTART_POS.bat.
#      ./restart.sh
# =====================================================================
set -uo pipefail

# git pull peut réécrire ce script pendant son exécution (bash lit le fichier
# au fil de l'eau) : on s'exécute depuis une copie temporaire.
if [ "${1:-}" != "--copie" ]; then
  ROOT=$(cd "$(dirname "$0")" && pwd)
  COPY="${TMPDIR:-/tmp}/poscaisse-restart.sh"
  cp "$0" "$COPY" && chmod +x "$COPY"
  exec bash "$COPY" --copie "$ROOT"
fi
ROOT="$2"
cd "$ROOT"

DB_HOST=${POSCAISSE_DB_HOST:-localhost}
DB_PORT=${POSCAISSE_DB_PORT:-5432}
DB_NAME=${POSCAISSE_DB_NAME:-poscaisse}
DB_USER=${POSCAISSE_DB_USER:-postgres}
PORT=${POSCAISSE_PORT:-8080}
export PGPASSWORD=${POSCAISSE_DB_PASSWORD:-postgres}

echo "=========================================================="
echo "  PosCaisse — redémarrage complet"
echo "=========================================================="
mkdir -p logs

kill_port() {
  local pids
  pids=$(ss -lptnH "sport = :$1" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | sort -u)
  [ -z "$pids" ] && pids=$(lsof -ti tcp:"$1" 2>/dev/null || true)
  [ -n "$pids" ] && kill $pids 2>/dev/null && sleep 2 && kill -9 $pids 2>/dev/null
  return 0
}

# ------------------------------------------------------------ 1. arrêt
echo
echo "[1/6] Arrêt des instances en cours…"
kill_port "$PORT"; kill_port 5173
pkill -f "poscaisse-backend.jar" 2>/dev/null || true
echo "    Ports $PORT et 5173 libérés."

# ------------------------------------------------------- 2. mise à jour
echo
echo "[2/6] Mise à jour du code…"
REBUILD=0
if command -v git >/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BEFORE=$(git rev-parse HEAD 2>/dev/null || echo none)
  git pull --ff-only || echo "    git pull a échoué (modifications locales ou réseau) : on continue avec le code présent."
  AFTER=$(git rev-parse HEAD 2>/dev/null || echo none)
  if [ "$BEFORE" = "$AFTER" ]; then echo "    Déjà à jour."; else echo "    Nouvelle version récupérée."; REBUILD=1; fi
else
  echo "    Hors dépôt git ou git absent : étape ignorée."
fi

# ------------------------------------------------------- 3. PostgreSQL
echo
echo "[3/6] PostgreSQL et base de données…"
if command -v docker >/dev/null && docker info >/dev/null 2>&1 && [ -f docker-compose.yml ]; then
  docker compose up -d postgres >/dev/null 2>&1 && echo "    PostgreSQL démarré via Docker."
elif command -v service >/dev/null; then
  service postgresql start >/dev/null 2>&1 || true
fi
if command -v psql >/dev/null; then
  for _ in $(seq 1 20); do
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc 'SELECT 1' >/dev/null 2>&1 && break
    sleep 2
  done
  if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null | grep -q 1; then
    echo "    Base \"$DB_NAME\" prête."
  else
    echo "    Base absente : création de \"$DB_NAME\"…"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;" >/dev/null \
      && echo "    Base créée." || echo "    Création impossible : créez la base manuellement."
  fi
else
  echo "    psql introuvable : vérification de la base ignorée."
fi

# ------------------------------------------------------- 4. compilation
echo
[ -f frontend/dist/index.html ] || REBUILD=1
[ -f backend/target/poscaisse-backend.jar ] || REBUILD=1
if [ "$REBUILD" = "0" ]; then
  echo "[4/6] Aucun changement : compilation inutile."
else
  echo "[4/6] Compilation (1 à 2 minutes)…"
  if command -v npm >/dev/null; then
    ( cd frontend && { [ -d node_modules ] || { echo "    Installation des dépendances npm…"; npm install --no-audit --no-fund; }; } \
      && echo "    Construction de l'interface…" && npm run build >/dev/null ) || echo "    ÉCHEC de la construction de l'interface."
  else
    echo "    npm introuvable : interface non compilée (installez Node.js)."
  fi
  if command -v mvn >/dev/null; then
    echo "    Construction du backend…"
    ( cd backend && mvn -q -B package -DskipTests ) || { echo "    ÉCHEC de la construction du backend."; exit 1; }
  else
    echo "    Maven introuvable : impossible de construire le backend."; exit 1
  fi
fi

# --------------------------------------------------------- 5. démarrage
echo
echo "[5/6] Démarrage du backend sur le port $PORT…"
# Le lancement doit être détaché : un sous-shell « ( … & ) » ferait attendre
# le script jusqu'à l'arrêt du backend (bash remplace le sous-shell par le
# processus java et l'attend en avant-plan).
cd backend
if [ -f target/poscaisse-backend.jar ]; then
  nohup java -jar target/poscaisse-backend.jar > ../logs/backend.log 2>&1 &
else
  nohup mvn -q spring-boot:run > ../logs/backend.log 2>&1 &
fi
BACKEND_PID=$!
disown "$BACKEND_PID" 2>/dev/null || true
cd "$ROOT"
echo "$BACKEND_PID" > backend.pid

# ----------------------------------------------------------- 6. attente
echo
echo "[6/6] Attente du démarrage…"
for i in $(seq 1 60); do
  sleep 2
  if curl -s "http://localhost:$PORT/actuator/health" | grep -q UP; then
    echo "    Backend prêt."
    echo
    echo "=========================================================="
    echo "  PosCaisse est lancé : http://localhost:$PORT"
    echo "=========================================================="
    echo
    echo "  Admin    admin / admin123      PIN 9999"
    echo "  Manager  manager / manager123  PIN 2222"
    echo "  Caissier Ahmed 1234 · Sami 5678 · Mariem 4321"
    echo
    echo "  Pour arrêter : ./stop.sh"
    command -v xdg-open >/dev/null && xdg-open "http://localhost:$PORT" >/dev/null 2>&1 &
    exit 0
  fi
done
echo "    Le backend ne répond pas — dernières lignes de logs/backend.log :"
tail -n 15 logs/backend.log
exit 1
