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
#
# Les fichiers .vbs suivent la meme regle pour la meme raison, a une nuance pres : le
# moteur de scripts de Windows lit l'ANSI par defaut et n'attend PAS de marque d'ordre
# des octets. On leur demande donc l'ASCII pur, et pas de marque.
set -euo pipefail
racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
souci=0

while IFS= read -r f; do
  bom=0; [ "$(head -c3 "$f" | od -An -tx1 | tr -d ' ')" = 'efbbbf' ] && bom=1
  # Une marque en double casse le langage aussi surement que pas de marque du tout :
  # elle arrive des qu'on relit un fichier deja marque sans le dire a l'outil.
  double=0; [ "$(head -c6 "$f" | tail -c3 | od -An -tx1 | tr -d ' ')" = 'efbbbf' ] && double=1
  # Octets hors ASCII, marque d'ordre exclue.
  horsascii=$(tail -c +4 "$f" | LC_ALL=C grep -c $'[\x80-\xff]' || true)
  if [ "$bom" = 0 ] || [ "$double" = 1 ] || [ "$horsascii" != 0 ]; then
    souci=1
    echo "  A REVOIR ${f#$racine/}  (marque : $([ $bom = 1 ] && echo oui || echo NON)$([ $double = 1 ] && echo ' EN DOUBLE'), lignes non-ASCII : $horsascii)"
  else
    echo "  ok       ${f#$racine/}"
  fi
done < <(find "$racine" -name '*.ps1' -not -path '*/node_modules/*' | sort)

while IFS= read -r f; do
  bom=0; [ "$(head -c3 "$f" | od -An -tx1 | tr -d ' ')" = 'efbbbf' ] && bom=1
  horsascii=$(LC_ALL=C grep -c $'[\x80-\xff]' "$f" || true)
  if [ "$bom" = 1 ] || [ "$horsascii" != 0 ]; then
    souci=1
    echo "  A REVOIR ${f#$racine/}  (marque : $([ $bom = 1 ] && echo 'A RETIRER' || echo non), lignes non-ASCII : $horsascii)"
  else
    echo "  ok       ${f#$racine/}"
  fi
done < <(find "$racine" -name '*.vbs' -not -path '*/node_modules/*' | sort)

if [ "$souci" != 0 ]; then
  echo
  echo "Remplacez les caracteres accentues ou typographiques par leur equivalent ASCII." >&2
  echo "Puis, pour un .ps1 : ajoutez la marque d'ordre des octets (UTF-8 avec BOM)." >&2
  echo "     pour un .vbs : retirez-la (le moteur de Windows ne l'attend pas)." >&2
  exit 1
fi
echo "  Tous les scripts sont lisibles par Windows PowerShell 5.1 et par cscript."
