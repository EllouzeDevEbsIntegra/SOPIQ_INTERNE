# Menu mural — trois téléviseurs

Trois fichiers, un par écran. Chacun s'affiche **en plein écran** sur son téléviseur et
n'a plus besoin de rien : polices et logo sont dans le fichier, aucun appel au réseau.

| Fichier | Écran | Contenu |
|---|---|---|
| `ecran-1-gauche.html` | gauche | Spécial, Classic, Lablebi |
| `ecran-2-centre.html` | centre | Mozarilla, Mozarilla 3arbi |
| `ecran-3-droite.html` | droite | Fromage, Boissons, Extras |

`mur-apercu.html` montre les trois à l'échelle, côte à côte — pour juger avant d'accrocher.

## Afficher

Sur le PC (ou la clé Android / mini-PC) branché à chaque téléviseur :

1. ouvrir le fichier de **cet** écran dans Chrome ou Edge ;
2. touche **F11** — plein écran, plus de barre d'adresse ;
3. dans les réglages du téléviseur, mettre le format d'image sur **« Just Scan »**,
   **« Screen Fit »** ou **« 1:1 »** selon la marque. Sans cela le téléviseur rogne les
   bords, et c'est la dernière ligne de prix qui disparaît.

Rien ne défile, rien ne tourne, rien ne clignote : la page est fixe. On peut la laisser
allumée toute la journée.

> Sur une dalle **OLED**, une image fixe pendant des mois marque l'écran. Sur du LCD /
> LED — ce qu'est la quasi-totalité des téléviseurs de 40 pouces — le risque est nul.

## Mettre les prix à jour

Les prix ne se retapent jamais ici. Ils viennent de la caisse :

```
D:\SOPIQ_INTERNE_POS\PosCaisse\EXPORTER_CARTE_SITE.bat
cd D:\SOPIQ_INTERNE_POS\PosCaisse\site
python3 outils\generer-site.py
cd ..\tv
python3 outils\generer-tv.py
```

Puis recopier les trois fichiers sur les postes des téléviseurs.

## Ce qui a été décidé, et pourquoi

**Un seul prix par ligne**, celui de la pâte normale. La carte en porte trois par
article ; à l'écran, trois colonnes divisent la taille du texte par deux et le tableau
devient illisible du fond de la salle. L'écart est le même partout — vérifié sur les
86 articles déclinés : céréale +1,000, chia +1,500 — donc il est dit **une fois, en
grand**, dans le bandeau rouge que porte chacun des trois écrans.

**Pas de photo dans les listes.** À cette densité une vignette coûte deux lignes de
texte, et le client qui lève les yeux cherche un prix. Les photos sont sur la caisse et
sur le site.

**Chaque écran se suffit.** L'enseigne, le bandeau des pâtes et le téléphone figurent
sur les trois : on ne regarde pas trois écrans, on regarde celui qui est en face de soi.

**La hauteur de ligne est calculée, pas choisie.** Le script répartit chaque écran en
deux colonnes de hauteur égale, puis descend la ligne juste ce qu'il faut pour que la
plus haute tienne dans la dalle — jamais plus bas. Aujourd'hui : 40,3 px à gauche,
41,1 px au centre, 38,5 px à droite, sur une base de 1920 × 1080.
