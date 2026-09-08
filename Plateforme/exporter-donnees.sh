#!/usr/bin/env bash
# Jumeau Linux de exporter-donnees.ps1 : exporte la base de ce poste vers un fichier.
# « --sans-ventes » (defaut) n'emporte que la carte et les reglages ; « --avec-ventes »
# fait une copie conforme.
set -euo pipefail
racine="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sortie="$racine/exports"; mkdir -p "$sortie"

ventes=0; [ "${1:-}" = '--avec-ventes' ] && ventes=1
tables=(print_job refund payment order_line_modifier order_line sale_order cash_movement
        register_journal daily_closure account_payment register_session document_sequence audit_log)

dbhost="${POSCAISSE_DB_HOST:-localhost}"; dbport="${POSCAISSE_DB_PORT:-5432}"
dbname="${POSCAISSE_DB_NAME:-poscaisse}"; dbuser="${POSCAISSE_DB_USER:-postgres}"
export PGPASSWORD="${POSCAISSE_DB_PASSWORD:-postgres}"

suffixe=$([ $ventes = 1 ] && echo complet || echo sans-ventes)
fichier="$sortie/poscaisse-$(date +%Y-%m-%d_%H%M)-$suffixe.dump"

args=(-h "$dbhost" -p "$dbport" -U "$dbuser" -d "$dbname" -Fc -f "$fichier")
if [ $ventes = 0 ]; then
  # --exclude-table-data garde la table et sa structure, mais laisse les lignes de cote.
  for t in "${tables[@]}"; do args+=(--exclude-table-data "public.$t"); done
fi
pg_dump "${args[@]}"
echo "  Fichier : $fichier ($(du -h "$fichier" | cut -f1))"
