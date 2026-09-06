#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Régénère le menu du site vitrine NUMBER ONE à partir du catalogue de la caisse.

Source  : catalogs/number-one-2026.json
Cible   : site/index.html  (blocs délimités par les marqueurs NAV et MENU)

Usage :
    python3 site/outils/generer-menu.py
    python3 site/outils/generer-menu.py --catalogue autre.json --page site/index.html

Règles appliquées :
  - tout article dont le prix vaut 0 est IGNORÉ (tarif pas encore fixé) ;
  - le prix affiché est celui de la pâte « Normale » quand l'article a des variantes ;
  - les prix sont écrits en dinars, trois décimales, virgule décimale (6,500 DT) ;
  - les noms des articles ne sont jamais corrigés ni renommés.
"""

import argparse
import json
import re
import sys
import unicodedata
from html import escape
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
CATALOGUE = RACINE / "catalogs" / "number-one-2026.json"
PAGE = RACINE / "site" / "index.html"

# Catégories dont les prix dépendent de la pâte : on rappelle discrètement
# que le tarif affiché est celui de la pâte Normale (le détail du supplément
# n'est expliqué qu'une seule fois, dans l'encadré « Les pâtes »).
VALEUR_PATE_DE_REFERENCE = "Normale"

# Texte d'introduction propre à certaines catégories.
INTROS = {
    "Extras": "Suppléments à ajouter sur n’importe quel sandwich — ce ne sont pas des plats.",
}


def slug(texte: str) -> str:
    """« Omlette Moz 3arbi » -> « omlette-moz-3arbi »."""
    sans_accent = unicodedata.normalize("NFKD", texte)
    sans_accent = "".join(c for c in sans_accent if not unicodedata.combining(c))
    sans_accent = sans_accent.replace("’", "-").replace("'", "-")
    sans_accent = re.sub(r"[^A-Za-z0-9]+", "-", sans_accent)
    return sans_accent.strip("-").lower()


def dinars(valeur: float) -> str:
    """3,500 -> « 3,500 DT » (trois décimales, virgule, espace insécable)."""
    return f"{valeur:.3f}".replace(".", ",") + "&nbsp;DT"


def prix_affiche(produit: dict):
    """Prix à montrer : celui de la pâte Normale si l'article a des variantes."""
    variantes = produit.get("variantPrices") or []
    for v in variantes:
        if v.get("value") == VALEUR_PATE_DE_REFERENCE:
            return v.get("price") or 0
    return produit.get("price") or 0


def construire(catalogue: dict):
    produits = catalogue.get("products", [])
    categories = sorted(catalogue.get("categories", []), key=lambda c: c.get("sortOrder", 0))

    retenus, ecartes = [], []
    for p in produits:
        (retenus if prix_affiche(p) > 0 else ecartes).append(p)

    nav, menu = [], []
    for cat in categories:
        nom = cat["name"]
        articles = [p for p in retenus if p.get("category") == nom]
        articles.sort(key=lambda p: (p.get("sortOrder", 0), p.get("code", "")))
        if not articles:
            continue

        ident = "cat-" + slug(nom)
        nav.append(
            f'        <li><a class="puce" href="#{ident}">{escape(nom)}</a></li>'
        )

        avec_pate = any(p.get("variantPrices") for p in articles)
        lignes = [
            f'      <section class="categorie" id="{ident}" aria-labelledby="{ident}-titre">',
            '        <header class="categorie-tete">',
            f'          <h3 id="{ident}-titre">{escape(nom)}</h3>',
            f'          <p class="categorie-compte">{len(articles)} article'
            f'{"s" if len(articles) > 1 else ""}</p>',
            "        </header>",
        ]
        if nom in INTROS:
            lignes.append(f'        <p class="categorie-intro">{escape(INTROS[nom])}</p>')
        if avec_pate:
            lignes.append(
                '        <p class="categorie-intro">Tarif de la pâte Normale — '
                '<a href="#les-pates">voir les autres pâtes</a>.</p>'
            )
        lignes.append('        <ul class="carte">')
        for p in articles:
            nom_article = escape(p["name"])
            prefixe = '<span class="plus" aria-hidden="true">+</span> ' if nom == "Extras" else ""
            etiquette = "Supplément" if nom == "Extras" else "Prix"
            lignes.append(
                f'          <li class="article" data-recherche="{escape(p["name"].lower())}">'
                f'<span class="article-nom">{nom_article}</span>'
                f'<span class="article-prix">{prefixe}'
                f'<span class="sr-only">{etiquette} : </span>{dinars(prix_affiche(p))}</span></li>'
            )
        lignes += ["        </ul>", "      </section>"]
        menu.append("\n".join(lignes))

    return "\n".join(nav), "\n\n".join(menu), retenus, ecartes


def remplacer(source: str, cle: str, contenu: str) -> str:
    debut, fin = f"<!-- {cle}:DEBUT -->", f"<!-- {cle}:FIN -->"
    motif = re.compile(re.escape(debut) + r".*?" + re.escape(fin), re.S)
    if not motif.search(source):
        sys.exit(f"Marqueurs {debut} … {fin} introuvables dans la page.")
    return motif.sub(lambda _: f"{debut}\n{contenu}\n{' ' * 6}{fin}", source, count=1)


def main() -> int:
    ap = argparse.ArgumentParser(description="Régénère le menu du site vitrine NUMBER ONE.")
    ap.add_argument("--catalogue", type=Path, default=CATALOGUE)
    ap.add_argument("--page", type=Path, default=PAGE)
    args = ap.parse_args()

    catalogue = json.loads(args.catalogue.read_text(encoding="utf-8"))
    nav, menu, retenus, ecartes = construire(catalogue)

    page = args.page.read_text(encoding="utf-8")
    page = remplacer(page, "NAV", nav)
    page = remplacer(page, "MENU", menu)
    args.page.write_text(page, encoding="utf-8")

    print(f"{args.page} mis à jour : {len(retenus)} articles affichés.")
    if ecartes:
        print(f"{len(ecartes)} article(s) écarté(s) faute de prix :")
        for p in ecartes:
            print(f"  - {p['code']}  {p['name']}  ({p['category']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
