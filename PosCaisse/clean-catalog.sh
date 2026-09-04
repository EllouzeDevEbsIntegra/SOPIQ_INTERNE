#!/usr/bin/env bash
# =====================================================================
#  Nettoyage définitif du catalogue PosCaisse.
#      ./clean-catalog.sh              catalogue seulement
#      ./clean-catalog.sh --ventes     + remise à zéro des ventes
#      ./clean-catalog.sh --ventes -y  sans confirmation
#
#  Sans --ventes : supprime les produits inactifs jamais vendus, les
#  catégories vides et les groupes d'options orphelins. L'historique des
#  tickets n'est pas touché.
#  Avec --ventes : efface d'abord toutes les données transactionnelles
#  (tickets, lignes, paiements, remboursements, mouvements, journal,
#  sessions, clôtures, numérotation), ce qui libère les produits inactifs
#  encore référencés. Irréversible.
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")"

URL="http://localhost:${POSCAISSE_PORT:-8080}"
PIN="${POSCAISSE_ADMIN_PIN:-9999}"
RESET=false
YES=false
for a in "$@"; do
  case "$a" in
    --ventes|--reset-ventes) RESET=true ;;
    -y|--oui) YES=true ;;
    *) echo "Option inconnue : $a"; exit 2 ;;
  esac
done

curl -sf "$URL/actuator/health" >/dev/null || {
  echo "PosCaisse ne répond pas sur $URL — lancez ./restart.sh d'abord."; exit 1; }

if [ "$YES" = false ]; then
  echo "Les articles et catégories inactifs seront SUPPRIMÉS, avec toutes leurs relations."
  [ "$RESET" = true ] && echo "TOUT l'historique des ventes sera également effacé. IRRÉVERSIBLE."
  read -r -p "Continuer ? [o/N] " rep
  case "$rep" in o|O|oui|OUI) ;; *) echo "Annulé."; exit 0 ;; esac
fi

TOKEN=$(curl -s -X POST "$URL/api/auth/pin" -H 'Content-Type: application/json' \
        -d "{\"pin\":\"$PIN\"}" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))' 2>/dev/null)
[ -n "$TOKEN" ] || { echo "Connexion administrateur refusée (PIN $PIN)."; exit 1; }

# Le rapport est mis en forme par python3 -c : un heredoc « python3 - » lirait
# stdin et consommerait la réponse de curl au lieu de la recevoir en pipe.
REPORT='
import json, sys
d = json.load(sys.stdin)
if d.get("code"):
    print("  Nettoyage refuse :", d.get("message")); sys.exit(1)
if d["salesReset"]:
    print("  Ventes     : %d ligne(s) effacee(s), numerotation remise a zero" % d["salesRowsDeleted"])
print("  Produits   : %d supprime(s), %d restant(s)" % (d["productsDeleted"], d["productsLeft"]))
print("  Categories : %d supprimee(s), %d restante(s)" % (d["categoriesDeleted"], d["categoriesLeft"]))
print("  Options    : %d groupe(s) orphelin(s) supprime(s)" % d["groupsDeleted"])
for w in d["warnings"]:
    print("  -", w)
print("  Base nettoyee. Rechargez le POS (F5).")
'
curl -s -X POST "$URL/api/catalog/purge?resetSales=$RESET" -H "Authorization: Bearer $TOKEN" \
  | python3 -c "$REPORT"
