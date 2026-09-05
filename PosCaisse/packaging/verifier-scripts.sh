#!/usr/bin/env bash
# Controle des scripts PowerShell du depot.
#
# Windows PowerShell 5.1 — celui livre avec Windows — lit un fichier sans marque d'ordre
# des octets comme de l'ANSI, pas comme de l'UTF-8. Un tiret cadratin « — » (E2 80 94) y
# devient « a€" », et ce dernier caractere est un guillemet fermant que le langage prend
# pour un delimiteur de chaine : le script est alors coupe en deux et refuse de demarrer,
# en signalant une erreur des dizaines de lignes plus bas que la vraie cause.
#
# Deux precautions valent mieux qu'une : les scripts portent une marque d'ordre des octets,
# et leur contenu reste en ASCII pur.
set -euo pipefail
racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
souci=0

while IFS= read -r f; do
  bom=0; [ "$(head -c3 "$f" | od -An -tx1 | tr -d ' ')" = 'efbbbf' ] && bom=1
  # Octets hors ASCII, marque d'ordre exclue.
  horsascii=$(tail -c +4 "$f" | LC_ALL=C grep -c $'[\x80-\xff]' || true)
  if [ "$bom" = 0 ] || [ "$horsascii" != 0 ]; then
    souci=1
    echo "  A REVOIR ${f#$racine/}  (marque d'ordre : $([ $bom = 1 ] && echo oui || echo NON), lignes non-ASCII : $horsascii)"
  else
    echo "  ok       ${f#$racine/}"
  fi
done < <(find "$racine" -name '*.ps1' -not -path '*/node_modules/*' | sort)

if [ "$souci" != 0 ]; then
  echo
  echo "Ajoutez la marque d'ordre des octets (UTF-8 avec BOM) et remplacez les caracteres" >&2
  echo "accentues ou typographiques par leur equivalent ASCII." >&2
  exit 1
fi
echo "  Tous les scripts PowerShell sont lisibles par Windows PowerShell 5.1."
