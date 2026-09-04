#!/usr/bin/env bash
# =====================================================================
#  Import d'une carte dans PosCaisse.
#     ./import-menu.sh [fichier.json] [--ajouter]
#  Par défaut : catalogs/number-one.json en mode remplacement.
#  Remplacement = ce qui n'est pas dans le fichier est supprimé, ou
#  simplement désactivé s'il a déjà été vendu (l'historique est préservé).
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")"

FILE="${1:-catalogs/number-one.json}"
REPLACE=true
[ "${2:-}" = "--ajouter" ] && REPLACE=false
URL="http://localhost:${POSCAISSE_PORT:-8080}"
PIN="${POSCAISSE_ADMIN_PIN:-9999}"

[ -f "$FILE" ] || { echo "Fichier introuvable : $FILE"; exit 1; }
curl -s "$URL/actuator/health" | grep -q UP || { echo "PosCaisse ne répond pas sur $URL — lancez ./restart.sh d'abord."; exit 1; }

TOKEN=$(curl -s -X POST "$URL/api/auth/pin" -H 'Content-Type: application/json' -d "{\"pin\":\"$PIN\"}" \
        | python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
[ -n "$TOKEN" ] || { echo "Connexion administrateur refusée (PIN $PIN)."; exit 1; }

echo "Import de « $FILE » (remplacement : $REPLACE)…"
curl -s -X POST "$URL/api/catalog/import?replace=$REPLACE" \
     -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json; charset=utf-8' \
     --data-binary "@$FILE" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
if 'message' in d and 'productsCreated' not in d:
    print('  Échec :', d['message']); sys.exit(1)
print(f\"  Catégories   : {d['categoriesCreated']} créées, {d['categoriesUpdated']} mises à jour, {d['categoriesDeactivated']} désactivées\")
print(f\"  Options      : {d['groupsCreated']} créées, {d['groupsUpdated']} mises à jour\")
print(f\"  Produits     : {d['productsCreated']} créés, {d['productsUpdated']} mis à jour, {d['productsDeactivated']} désactivés\")
for w in d.get('warnings', []): print('  •', w)
print('  Carte importée. Rechargez le POS (F5) pour la voir.')
"
