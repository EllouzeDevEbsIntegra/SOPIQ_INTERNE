# Menu mural — trois téléviseurs

Trois fichiers, un par écran. Chacun s'affiche **en plein écran** sur son téléviseur et
n'a plus besoin de rien : polices et logo sont dans le fichier, aucun appel au réseau.

| Fichier | Écran | Contenu |
|---|---|---|
| `ecran-1-gauche.html` | gauche | Classic, Fromage |
| `ecran-2-centre.html` | centre | Mozarilla + Mozarilla 3arbi, en tableau croisé |
| `ecran-3-droite.html` | droite | Spécial, Lablebi, Boissons, Extras |

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

**Les trois prix sur la ligne** — normale, céréale, chia. Un client qui doit ajouter
+1,000 de tête devant un tableau hésite, et un client qui hésite ne commande pas. Les
colonnes ne coûtent rien à la lisibilité : c'est la **hauteur** de la ligne qui commande
la taille du texte, et elle ne change pas — les trois prix tiennent dans la largeur qui
restait libre à droite. Seule la **double pâte** reste une règle, dans le bandeau rouge :
+1,000, et +1,500 en chia.

**L'écran du centre est un tableau croisé.** Mozarilla et Mozarilla 3arbi portent
exactement les mêmes 19 garnitures, dans le même ordre — vérifié article par article, le
script s'arrête si ce n'est plus vrai. Les écrire deux fois faisait lire deux fois la
même liste sur 38 lignes, et obligeait à sauter d'une colonne à l'autre pour comparer les
deux fromages. Une garniture par ligne, six prix à droite en deux blocs : **19 lignes au
lieu de 38**, et la place gagnée passe dans la taille des chiffres.

**Une image de fond par écran**, dans `fond/` — voir le `LISEZ-MOI.txt` qui s'y trouve.
Elle s'affiche à 15 % dans le bas de la dalle et s'efface en montant, pour réchauffer le
noir sans jamais disputer un chiffre. Sans image, l'écran reste noir : le tableau ne
dépend pas d'elle.

**Pas de photo dans les listes.** À cette densité une vignette coûte deux lignes de
texte, et le client qui lève les yeux cherche un prix. Les photos sont sur la caisse et
sur le site.

**Chaque écran se suffit.** L'enseigne, le bandeau des pâtes et le téléphone figurent
sur les trois : on ne regarde pas trois écrans, on regarde celui qui est en face de soi.

**La hauteur de ligne est calculée, pas choisie — et elle est la même sur les trois.**
Le script répartit chaque écran en deux colonnes de hauteur égale, puis descend la ligne
juste ce qu'il faut pour que la plus chargée des trois dalles tienne — jamais plus bas.
C'est donc l'écran le plus rempli qui décide pour tous : les trois sont côte à côte sur
le même mur, et un titre de 30 px à gauche contre 28 à droite ne se remarque pas écran
par écran, mais se voit dès qu'on prend du recul. Aujourd'hui, sur une base de
1920 × 1080 : ligne 39,5 px, titre de rubrique 28,5, nom d'article 23,9, prix 25,4,
intitulé de pâte 17,7 — identiques sur les trois écrans.
