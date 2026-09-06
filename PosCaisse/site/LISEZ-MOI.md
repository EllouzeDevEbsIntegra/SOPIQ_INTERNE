# Site NUMBER ONE

Page unique et statique : `index.html`, plus un dossier de photos. Aucune base, aucun
serveur, aucune dépendance à installer — elle s'ouvre par double-clic, se copie sur une
clé, ou s'héberge n'importe où.

## Ce qu'elle affiche

Les **110 articles** de la carte qui ont un prix, en 12 catégories. Un article dont le
prix vaut zéro n'est **pas publié** : un menu public qui annonce un prix faux coûte plus
cher qu'un menu incomplet. Aujourd'hui, sept articles attendent leur tarif — Coca, Eau
0,5 L, Grillade, Nuggets x6, et les extras Fromage Slice, Grillade et Nuggets x6.

Chaque sandwich montre ses **trois prix sur la même ligne** : Normale, Céréale, Chia. Le
client lit le prix de sa pâte, il ne fait pas l'addition.

## Poser les photos

Les images vont dans `img/`, nommées comme la page les attend :
`omlette-mozarilla-thon.png` pour « Omlette Mozarilla Thon ». Le script s'en charge :

```powershell
cd D:\SOPIQ_INTERNE_POS\PosCaisse\site
.\outils\copier-photos.ps1 -Source 'C:\Users\administrateur\Downloads\image POS\reduit'
```

Il copie, renomme, et **nomme à la fin** les fichiers qui ne correspondent à aucun
article et les articles restés sans photo. Rien à régénérer ensuite : la page cherche
l'image au chargement, et affiche l'initiale de l'article quand le fichier manque.

Le **logo** va au même endroit, sous le nom `img/logo-number-one.png`. Sans lui, la page
reste correcte : le nom est un lettrage en texte, l'image se retire d'elle-même.

## Mettre la carte à jour

Les prix vivent dans la caisse, pas ici. Deux commandes, dans cet ordre.

**1. Prendre la carte du poste** (la caisse doit tourner) :

```
D:\SOPIQ_INTERNE_POS\PosCaisse\EXPORTER_CARTE_SITE.bat
```

Il écrit `site/carte-live.json` : les catégories dans leur ordre d'affichage, les
articles avec leur nom, leur prix, leurs trois prix de pâte **et leurs photos**, tels
qu'ils sont dans la caisse aujourd'hui. Il annonce au passage les articles sans photo et
ceux restés à 0,000.

**2. Réécrire la page** :

```
python3 outils/generer-site.py
```

Il lit `carte-live.json` s'il existe, sinon le fichier d'import
`../catalogs/number-one-2026.json`. Les photos de la caisse sont posées dans `img/` pour
les articles qui n'en ont pas encore — un fichier déjà présent n'est **jamais écrasé**,
il vient du dossier d'origine en pleine définition alors que la caisse ne garde qu'une
vignette de 240 px.

Aucun prix n'est retapé à la main : c'est la seule façon d'avoir un site qui ne ment pas.

## Ce qu'il reste à fournir

- le logo officiel en bonne définition ;
- les **horaires** d'ouverture ;
- la page Facebook ou Instagram, s'il y en a une ;
- les sept prix manquants ;
- le nom de domaine, pour rendre l'adresse de l'image de partage absolue.

## Un point à trancher

Les extras contiennent « Pâte Céréale 2,000 » et « Pâte Chia 2,500 », alors que changer
la pâte d'un sandwich coûte +1,000 et +1,500. Ce ne sont probablement pas la même chose
— une galette vendue seule d'un côté, un supplément de l'autre — mais un client verra
les deux sur la page. À confirmer avant publication.
