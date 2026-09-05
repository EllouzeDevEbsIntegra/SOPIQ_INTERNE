#!/usr/bin/env bash
# PosCaisse — poste autonome, sans internet (Linux / macOS).
#
# Jumeau de poscaisse.ps1 : meme arborescence, memes actions, meme configuration.
# Tout vit dans ce dossier — moteur Java, serveur PostgreSQL, application, donnees.
# Rien n'est installe dans le systeme, aucun service n'est enregistre.
set -euo pipefail

racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
jre="$racine/jre"; pg="$racine/pgsql"; donnees="$racine/donnees"
journal="$racine/journaux"; config="$racine/config/poscaisse.conf"; sauve="$racine/sauvegardes"
jar="$racine/poscaisse.jar"
mkdir -p "$journal" "$sauve" "$(dirname "$config")"

# Le paquet embarque son propre moteur ; a defaut, celui du systeme fait l'affaire.
java_bin="$jre/bin/java"; [ -x "$java_bin" ] || java_bin="$(command -v java || true)"
pgbin="$pg/bin"; [ -x "$pgbin/initdb" ] || pgbin="$(dirname "$(command -v initdb 2>/dev/null || echo /usr/lib/postgresql/16/bin/initdb)")"

info()  { echo "  $*"; }
etape() { echo; echo "== $*"; }
souci() { echo "  $*" >&2; }
arret() { echo; echo "ARRET : $*" >&2; exit 1; }

lire_config() {
  PG_PORT=5433; APP_PORT=8080; DB=poscaisse; USER=poscaisse; PASS=""; KIOSQUE=0
  # « if » et non « && » : sans fichier de configuration, une liste ET renvoie un echec,
  # et sous « set -e » c'est l'appelant qui s'arrete, sans le moindre message.
  if [ -f "$config" ]; then . "$config"; fi
}
ecrire_config() {
  { echo "# Reglages du poste PosCaisse."
    for k in PG_PORT APP_PORT DB USER PASS KIOSQUE; do echo "$k=${!k}"; done
  } > "$config"
  chmod 600 "$config"
}
# 96 bits tires au hasard, en hexadecimal. Sans tuyau : « head » refermerait le canal
# avant la fin de l'ecriture, et sous « pipefail » le script s'arreterait sans un mot.
mot_de_passe() {
  local h; h="$(od -An -tx1 -N16 /dev/urandom)"
  printf '%s' "${h//[^0-9a-f]/}"
}

pg_tourne() { [ -d "$donnees" ] && "$pgbin/pg_ctl" -D "$donnees" status >/dev/null 2>&1; }
pg_demarre() {
  pg_tourne && return 0
  if ! "$pgbin/pg_ctl" -D "$donnees" -l "$journal/postgres.log" \
        -o "-p $PG_PORT -c listen_addresses=127.0.0.1" -w -t 60 start >/dev/null; then
    # Le cas de loin le plus frequent sur un poste deja equipe : un autre PostgreSQL
    # occupe le port. Le dire, plutot que de renvoyer l'utilisateur a un journal.
    if grep -q 'Address already in use' "$journal/postgres.log" 2>/dev/null; then
      souci "Le port $PG_PORT est deja pris par un autre programme."
      souci "Ouvrez config/poscaisse.conf, remplacez PG_PORT=$PG_PORT par une autre valeur"
      souci "(5434, 5435...), puis relancez."
      arret 'Port de base de donnees indisponible.'
    fi
    tail -n 6 "$journal/postgres.log" >&2
    arret "PostgreSQL n'a pas demarre (voir ci-dessus, et journaux/postgres.log)."
  fi
}
pg_arrete() { pg_tourne && "$pgbin/pg_ctl" -D "$donnees" -m fast -w -t 60 stop >/dev/null || true; }

app_repond() { curl -sf "http://127.0.0.1:$APP_PORT/actuator/health" 2>/dev/null | grep -q '"status":"UP"'; }
app_demarre() {
  app_repond && { info 'Application deja en service.'; return 0; }
  ( cd "$racine" && setsid nohup "$java_bin" -Xms256m -Xmx768m \
      -Duser.timezone=Africa/Tunis -Dfile.encoding=UTF-8 -jar "$jar" \
      "--server.port=$APP_PORT" \
      "--spring.datasource.url=jdbc:postgresql://127.0.0.1:$PG_PORT/$DB" \
      "--spring.datasource.username=$USER" "--spring.datasource.password=$PASS" \
      > "$journal/poscaisse.log" 2>&1 & )
  info 'Demarrage de la caisse...'
  for _ in $(seq 1 90); do app_repond && { info 'Caisse prete.'; return 0; }; sleep 2; done
  if grep -qi 'port .* was already in use\|Address already in use' "$journal/poscaisse.log" 2>/dev/null; then
    souci "Le port $APP_PORT est deja pris par un autre programme."
    souci "Ouvrez config/poscaisse.conf, remplacez APP_PORT=$APP_PORT par une autre valeur (8081...),"
    souci 'puis relancez.'
    arret 'Port de la caisse indisponible.'
  fi
  tail -n 10 "$journal/poscaisse.log" >&2
  arret "La caisse n'a pas repondu en 3 minutes (voir ci-dessus)."
}
app_arrete() { pkill -f "$jar" >/dev/null 2>&1 || true; }

faire_install() {
  etape 'Verification du contenu du dossier'
  [ -x "$java_bin" ] || arret "Moteur Java introuvable."
  [ -x "$pgbin/initdb" ] || arret "PostgreSQL introuvable."
  [ -f "$jar" ] || arret "poscaisse.jar introuvable."
  info 'Moteur Java, PostgreSQL et application presents.'

  if [ -f "$donnees/PG_VERSION" ]; then
    souci 'Une base existe deja : installation deja faite.'
    souci "Pour repartir de zero, renommez le dossier « donnees » puis relancez."
    return 0
  fi
  lire_config
  [ -n "$PASS" ] || PASS="$(mot_de_passe)"
  ecrire_config

  etape 'Creation de la base de donnees'
  pwf="$(mktemp)"; printf '%s' "$PASS" > "$pwf"
  # Le serveur n'ecoute que la machine elle-meme et exige un mot de passe.
  # La sortie va dans le journal : masquer l'echec d'initdb laisserait l'installation
  # s'arreter sans dire pourquoi (compte root refuse, dossier non inscriptible...).
  if ! "$pgbin/initdb" -D "$donnees" -U "$USER" --pwfile="$pwf" -A scram-sha-256 -E UTF8 --locale=C \
        > "$journal/initdb.log" 2>&1; then
    rm -f "$pwf"
    souci "--- fin de journaux/initdb.log ---"; tail -n 8 "$journal/initdb.log" >&2
    arret "La creation du serveur de base a echoue (voir ci-dessus)."
  fi
  rm -f "$pwf"
  info "Serveur cree, compte « $USER »."
  pg_demarre
  PGPASSWORD="$PASS" "$pgbin/psql" -h 127.0.0.1 -p "$PG_PORT" -U "$USER" -d postgres -c "CREATE DATABASE $DB;" >/dev/null
  info "Base « $DB » creee."

  etape 'Premier demarrage'
  app_demarre
  info 'Tables et donnees de depart installees.'
  etape 'Installation terminee'
  info "Ouvrez la caisse : ./outils/poscaisse.sh start — identifiants admin / admin123."
  souci 'Changez ce mot de passe des la premiere connexion.'
}

faire_start() {
  [ -f "$donnees/PG_VERSION" ] || arret "Rien n'est installe : lancez d'abord « install »."
  lire_config; pg_demarre; app_demarre
  info "Caisse ouverte : http://127.0.0.1:$APP_PORT/"
  [ "${KIOSQUE:-0}" = 1 ] && command -v xdg-open >/dev/null && xdg-open "http://127.0.0.1:$APP_PORT/" >/dev/null 2>&1 || true
}
faire_stop()   { lire_config; app_arrete; pg_arrete; info 'Caisse et base arretees.'; }
faire_backup() {
  lire_config; pg_demarre
  f="$sauve/poscaisse-$(date +%Y-%m-%d_%H%M).dump"
  PGPASSWORD="$PASS" "$pgbin/pg_dump" -h 127.0.0.1 -p "$PG_PORT" -U "$USER" -d "$DB" -Fc -f "$f"
  info "Sauvegarde ecrite : $f"
  souci 'Copiez ce fichier hors du poste : ici, il ne survivrait pas a une panne de disque.'
}
# Supprime une base, apres avoir coupe ce qui y est encore connecte : la caisse se
# rebranche des que PostgreSQL revient, et une seule connexion fait echouer la suppression.
vider_base() {
  q -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$1' AND pid <> pg_backend_pid();" >/dev/null
  q -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $1;" >/dev/null \
    || arret "La base $1 n'a pas pu etre supprimee : un programme y est encore connecte."
}

faire_restore() {
  [ -f "${2:-}" ] || arret "Indiquez le fichier de sauvegarde a restaurer."
  lire_config
  tampon="${DB}_import"
  q() { "$pgbin/psql" -h 127.0.0.1 -p "$PG_PORT" -U "$USER" "$@"; }

  # 1. Le fichier est-il seulement lisible ? Rien n'est touche tant qu'on n'en est pas sur.
  etape 'Verification du fichier'
  taille=$(stat -c%s "$2")
  [ "$taille" -ge 1024 ] || arret "Le fichier ne fait que $taille octets : il est vide ou incomplet."
  info "Fichier : $((taille / 1024)) Ko"

  app_arrete; pg_demarre
  export PGPASSWORD="$PASS"
  "$pgbin/pg_restore" -l "$2" >/dev/null 2>&1 || arret "Ce fichier n'est pas une sauvegarde PosCaisse lisible."
  info 'Sauvegarde lisible.'

  # 2. On la depose dans une base a part, pour la regarder. La base en service n'est pas
  #    touchee : si quoi que ce soit se passe mal, le poste continue de fonctionner.
  etape 'Lecture du contenu'
  vider_base "$tampon"
  q -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $tampon;" >/dev/null || arret 'Base de travail impossible a creer.'
  "$pgbin/pg_restore" -h 127.0.0.1 -p "$PG_PORT" -U "$USER" -d "$tampon" --no-owner --no-privileges "$2" 2>&1 | grep -i error || true

  bilan=$(q -d "$tampon" -tAc "select coalesce((select coalesce(trade_name, name) from company limit 1), '(aucune)') || '|' || (select count(*) from product) || '|' || (select count(*) from category) || '|' || (select count(*) from sale_order)" 2>/dev/null || echo '')
  [ -n "$bilan" ] || { vider_base "$tampon"; arret "Le fichier ne contient pas une base PosCaisse exploitable."; }
  echo
  echo '  Ce que contient ce fichier :'
  echo "    Enseigne   : $(echo "$bilan" | cut -d'|' -f1)"
  echo "    Articles   : $(echo "$bilan" | cut -d'|' -f2)"
  echo "    Categories : $(echo "$bilan" | cut -d'|' -f3)"
  echo "    Tickets    : $(echo "$bilan" | cut -d'|' -f4)"

  # 3. Maintenant seulement, on remplace.
  actuel=$(q -d "$DB" -tAc "select coalesce((select coalesce(trade_name, name) from company limit 1), '(aucune)') || ', ' || (select count(*) from product) || ' articles'" 2>/dev/null || echo '(base illisible)')
  echo
  echo "  Le poste contient aujourd'hui : $actuel"
  echo '  Tout cela sera REMPLACE par le contenu ci-dessus.'
  read -r -p '  Tapez OUI pour remplacer : ' rep
  if [ "$rep" != OUI ]; then vider_base "$tampon"; info "Abandon : le poste n'a pas ete modifie."; return 0; fi

  etape 'Remplacement'
  vider_base "$DB"
  q -d postgres -v ON_ERROR_STOP=1 -c "ALTER DATABASE $tampon RENAME TO $DB;" >/dev/null \
    || arret "Le remplacement a echoue : la base restauree s'appelle encore $tampon."
  info "Le poste contient maintenant : $(echo "$bilan" | cut -d'|' -f1), $(echo "$bilan" | cut -d'|' -f2) articles."
}

faire_status() {
  lire_config
  pg_tourne && info "Base de donnees : en service (port $PG_PORT)" || info 'Base de donnees : arretee'
  app_repond && info "Caisse          : en service (http://127.0.0.1:$APP_PORT/)" || info 'Caisse          : arretee'
  info "Dossier         : $racine"
}

case "${1:-start}" in
  install) faire_install ;;
  start)   faire_start ;;
  stop)    faire_stop ;;
  backup)  faire_backup ;;
  restore) faire_restore "$@" ;;
  status)  faire_status ;;
  *) echo "Usage : $0 {install|start|stop|backup|restore <fichier>|status}" ; exit 2 ;;
esac
