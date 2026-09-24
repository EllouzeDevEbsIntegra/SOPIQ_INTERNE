#!/usr/bin/env python3
"""
CONVERTIR L'EXPORT D'UN AUTRE LOGICIEL DE CAISSE EN CARTE POSCAISSE.

Ecrit pour la reprise du premier client venu d'un logiciel tunisien courant, dont l'export
porte des colonnes prefixees ART_. Il resservira : c'est la situation de tout commercant
qui change de caisse, et il n'acceptera pas de ressaisir quinze mille articles.

    python3 convertir-export-csv.py articles.csv [codes-barres.csv] > carte.json

CE QUE LE SCRIPT NE DEVINE PAS, ET POURQUOI.

    LE PRIX. L'export observe portait ses prix dans PrixSolde, les colonnes
    ART_PrixUnitaireHT etant a zero sur les 395 lignes. Ce n'est PAS une regle generale :
    --colonne-prix permet de nommer la bonne colonne, et il faut la verifier sur trois
    articles connus avant d'importer. Un prix faux ne se decouvre qu'au moment ou un
    client paie.

    LA TVA. Absente de l'export. Les articles arrivent a 0 et le taux se pose par famille
    dans le back-office - une valeur inventee ici s'imprimerait sur des tickets.

    LE STOCK. L'export observe donnait des quantites NEGATIVES (-8, -250). Une quantite
    fausse rend un article invendable en rupture : on n'importe donc aucun stock, jamais.
    Le commercant fait son inventaire, c'est le seul chiffre qui vaille.

CE QU'IL POSE. Un article sans prix entre avec le drapeau « prix a verifier » plutot qu'a
zero : la caisse le signale au lieu de le vendre gratuitement.
"""
import argparse, csv, collections, io, json, re, sys


def lire(chemin):
    # utf-8-sig : ces exports portent une marque d'ordre des octets, qui collerait au nom
    # de la premiere colonne et la rendrait introuvable.
    with io.open(chemin, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f, delimiter=";"))


def nombre(v):
    if v is None or v.strip() in ("", "NULL"):
        return None
    try:
        return round(float(v.replace(",", ".")), 3)
    except ValueError:
        return None


def texte(v):
    return None if v is None or v.strip() in ("", "NULL") else v.strip()


def main():
    a = argparse.ArgumentParser()
    a.add_argument("articles")
    a.add_argument("codes_barres", nargs="?")
    a.add_argument("--colonne-prix", default="PrixSolde")
    a.add_argument("--libelle", default="Reprise de carte")
    a.add_argument("--familles", help="fichier code=nom, une ligne par famille")
    o = a.parse_args()

    lignes = lire(o.articles)
    if o.colonne_prix not in (lignes[0] if lignes else {}):
        sys.exit("Colonne de prix « %s » absente. Colonnes : %s"
                 % (o.colonne_prix, ", ".join(sorted(lignes[0].keys()))[:400]))

    # Les codes-barres supplementaires, groupes par code parent.
    secondaires = collections.defaultdict(list)
    if o.codes_barres:
        for l in lire(o.codes_barres):
            parent, fils = texte(l.get("Parent_CodeBar")), texte(l.get("Fils_CodeBar"))
            if parent and fils and fils != parent and fils not in secondaires[parent]:
                secondaires[parent].append(fils)

    noms = {}
    if o.familles:
        with io.open(o.familles, encoding="utf-8") as f:
            for l in f:
                if "=" in l:
                    k, v = l.split("=", 1)
                    noms[k.strip()] = v.strip()

    familles, produits, sans_prix = {}, [], 0
    for l in lignes:
        code = texte(l.get("ART_Code"))
        nom = texte(l.get("ART_Designation"))
        if not code or not nom:
            continue
        fam = texte(l.get("ART_Famille")) or "000"
        familles.setdefault(fam, noms.get(fam, "Famille " + fam))

        prix = nombre(l.get(o.colonne_prix)) or 0.0
        if prix <= 0:
            sans_prix += 1
        cb = texte(l.get("ART_CodeBar"))
        court = texte(l.get("ART_DesgCourte"))

        p = {
            "code": code,
            "name": nom,
            "category": familles[fam],
            "price": prix,
            "taxRate": 0,
            # Le prix a verifier plutot que zero : la caisse le signale au lieu de le
            # vendre gratuitement.
            "priceToCheck": prix <= 0,
            "unite": "PIECE",
            # Le stock reste GERE MAIS NON RENSEIGNE : une quantite fausse rendrait
            # l'article invendable en rupture des le premier jour.
            "stockManaged": False,
        }
        if court and court != nom:
            p["shortName"] = court
        if cb:
            p["barcode"] = cb
            if secondaires.get(cb):
                p["barcodesSecondaires"] = secondaires[cb]
        produits.append(p)

    carte = {
        "label": o.libelle,
        "categories": [{"name": n, "sortOrder": i + 1}
                       for i, (c, n) in enumerate(sorted(familles.items()))],
        "products": produits,
    }
    sys.stderr.write("%d articles, %d catégories, %d sans prix (« à vérifier »), %d codes secondaires\n"
                     % (len(produits), len(familles), sans_prix,
                        sum(len(v) for v in secondaires.values())))
    print(json.dumps(carte, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
