#!/usr/bin/env bash
# Fabrique le paquet autonome de PosCaisse pour un poste Linux.
#
# Jumeau de build-bundle.ps1. Sur Linux le moteur Java et PostgreSQL du systeme sont
# utilises s'ils sont presents : le paquet ne les embarque que si on lui fournit les
# archives dans « telechargements ». Sert aussi a valider la chaine sans machine Windows.
set -euo pipefail

version="${1:-$(date +%Y.%m.%d)}"
ici="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projet="$(dirname "$ici")"
sortie="$ici/dist/PosCaisse-$version"

etape() { echo; echo "== $*"; }
info()  { echo "  $*"; }
arret() { echo; echo "ARRET : $*" >&2; exit 1; }

etape 'Controle des scripts PowerShell'
"$ici/verifier-scripts.sh"

etape "Compilation de l'interface"
( cd "$projet/frontend" && npm ci --no-audit --no-fund >/dev/null && npm test >/dev/null && npm run build >/dev/null ) \
  || arret "La compilation de l'interface a echoue."
info 'Interface compilee.'

etape "Compilation de l'application (interface incluse dans le JAR)"
( cd "$projet/backend" && mvn -q -B -Pbundle package ) || arret 'La compilation du backend a echoue.'
info 'JAR autonome produit.'

etape 'Assemblage du paquet'
rm -rf "$sortie"; mkdir -p "$sortie"
cp "$projet/backend/target/poscaisse-backend.jar" "$sortie/poscaisse.jar"
cp -r "$ici/bundle/." "$sortie/"
[ -d "$projet/catalogs" ] && cp -r "$projet/catalogs" "$sortie/"
# Les lanceurs Windows n'ont rien a faire dans un paquet Linux.
rm -f "$sortie"/*.bat
chmod +x "$sortie/outils/poscaisse.sh"
echo "PosCaisse $version — paquet autonome" > "$sortie/VERSION.txt"

for f in poscaisse.jar outils/poscaisse.sh; do
  [ -e "$sortie/$f" ] || arret "Le paquet est incomplet : $f manque."
done

etape 'Compression'
tar -czf "$sortie.tar.gz" -C "$(dirname "$sortie")" "$(basename "$sortie")"
info "Dossier : $sortie"
info "Archive : $sortie.tar.gz ($(du -h "$sortie.tar.gz" | cut -f1))"
info "Sur le poste : decompressez, puis ./outils/poscaisse.sh install"
