# Menu mural — trois téléviseurs

Trois fichiers, un par écran. Chacun s'affiche **en plein écran** sur son téléviseur et
n'a plus besoin de rien : polices et logo sont dans le fichier, aucun appel au réseau.

| Fichier | Écran | Contenu |
|---|---|---|
| `ecran-1-gauche.html` | gauche | Classic + Fromage, en tableau croisé |
| `ecran-2-centre.html` | centre | Mozarilla + Mozarilla 3arbi, en tableau croisé |
| `ecran-3-droite.html` | droite | Spécial, Lablebi, Boissons, Extras |

`mur-apercu.html` montre les trois à l'échelle, côte à côte — pour juger avant d'accrocher.

## Deux mises en page, à faire choisir

Les mêmes articles et les mêmes prix se rangent de deux façons sur les écrans de gauche
et du centre. L'écran de droite ne change pas.

| Version | Où | Comment ça se lit |
|---|---|---|
| **Tableaux croisés** | `tv/` | Une ligne par garniture, six prix à droite en deux blocs. On compare deux versions d'un même sandwich d'un coup d'œil, mais il faut lire l'en-tête pour savoir quelle colonne est laquelle. |
| **Listes séparées** | `tv/variante-listes/` | Chaque famille forme un bloc entier, avec son titre et ses trois prix. On lit droit devant soi, mais le même nom revient quatre fois sur le mur. |

```
python3 outils/generer-tv.py            les tableaux croisés
python3 outils/generer-tv.py listes     les listes séparées
python3 outils/comparer.py              comparaison.html, les deux d'un bouton
```

## Deux palettes

Les mêmes tableaux, à la même géométrie, repeints. C'est la seule façon de comparer
deux couleurs sans comparer autre chose en même temps.

| Palette | Où | Ce que ça donne |
|---|---|---|
| **Nuit** | `tv/`, `tv/variante-listes/` | Fond noir, prix en or. Le tableau s'efface, les chiffres avancent. |
| **Crème** | `tv/variante-clair/`, `tv/variante-listes-clair/` | Fond crème, prix à l'encre, rouge brique sur les titres, l'enseigne et le téléphone. Plus proche d'une carte imprimée. |

```
python3 outils/generer-tv.py croise clair    les tableaux croisés, en crème
python3 outils/generer-tv.py listes clair    les listes séparées, en crème
python3 outils/propositions.py               propositions.html, les QUATRE d'un menu
```

`propositions.html` est la page à montrer au client : un menu en haut, deux boutons par
ligne (disposition, couleurs), et les trois écrans se repeignent dessous. Les quatre
versions y sont rendues à la même hauteur de ligne — la plus basse des quatre — pour
qu'il juge la mise en page et non le corps du texte ; les fichiers qui partent sur les
dalles, eux, sont refaits à leur taille naturelle.

**Un tableau clair n'est pas un tableau sombre inversé.** Sur crème, c'est l'encre qui
porte le mieux les chiffres et le rouge qui devient l'accent ; sur noir, l'or tenait les
deux rôles à la fois. Le rouge s'arrête aux titres, à l'enseigne et au téléphone : une
colonne de prix entière en rouge faisait, sur dix-neuf lignes, une barre que l'œil
suivait avant de lire le nom du sandwich.

### Le logo sur fond crème

Le fichier livré est dessiné pour du noir : fond noir, et le mot NUMBER en doré. Posé
tel quel sur du crème, il montre un carré noir, et son doré s'éteint sur un fond chaud.
Le générateur l'adapte donc tout seul — fond repeint par diffusion depuis les quatre
coins (les noirs du dessin restent noirs), et le mot NUMBER passé à l'encre, la bande du
haut seulement : plus bas, l'or est celui de la pâte et des flammes, à sa place.

Si vous avez le logo déjà dessiné pour fond clair, déposez-le ici :

```
PosCaisse/site/img/logo-number-one-clair.png
```

C'est lui qui sera pris, sans rien demander. Son fond est quand même ramené au crème
exact du tableau : deux tons d'écart laisseraient voir son carré.

Contrairement à ce qu'on croirait, la version en listes ne rapetisse rien : elle tient à
**une hauteur de ligne au moins égale** à celle des tableaux croisés. Les 38 articles d'un écran se rangent en deux colonnes de
19, soit la même hauteur que les 19 lignes d'une matrice — qui paie en plus une rangée
d'en-tête de second niveau. Le choix se joue donc sur la lecture, pas sur la taille.

`comparaison.html` rend les deux **à la même hauteur de ligne**, pour que l'œil juge la
mise en page et non le corps du texte.

Un seul des deux dossiers part sur les téléviseurs.

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

**La règle des doubles pâtes est en pied de tableau, en sourdine.** Elle occupait un
bandeau rouge pleine largeur en tête : la première chose que le client lisait était donc
un supplément, avant même d'avoir cherché son sandwich. Un rouge vif et des capitales
promettent une offre ; ce n'en est pas une, c'est une précision de tarif. Elle est
descendue sous les prix, en petit, sur un simple filet — elle répond à la question au
moment où elle se pose. Les 18 px gagnés sont revenus aux lignes du menu.

**Les trois prix sur la ligne** — normale, céréale, chia. Un client qui doit ajouter
+1,000 de tête devant un tableau hésite, et un client qui hésite ne commande pas. Les
colonnes ne coûtent rien à la lisibilité : c'est la **hauteur** de la ligne qui commande
la taille du texte, et elle ne change pas — les trois prix tiennent dans la largeur qui
restait libre à droite. Seule la **double pâte** reste une règle, dans le bandeau rouge :
+1,000, et +1,500 en chia.

**Les deux premiers écrans sont des tableaux croisés**, parce que la carte est bâtie
ainsi : les mêmes **19 garnitures** se déclinent nature, au fromage, à la mozarilla et à
la mozarilla 3arbi. Les écrire quatre fois en listes faisait lire quatre fois la même
suite de noms, et obligeait à sauter d'une colonne à l'autre pour comparer deux versions.
Une garniture par ligne, six prix à droite en deux blocs : **19 lignes au lieu de 38**.

Les familles s'apparient par le **nom** de la garniture, pas par leur rang : déplacer un
article dans le back-office ne peut donc pas décaler une colonne d'une ligne, ce qui
ferait comparer deux plats différents sans que rien ne le signale. Ce qui manque d'un
côté **arrête le script** au lieu de publier un tableau troué.

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
par écran, mais se voit dès qu'on prend du recul. La valeur du jour est annoncée par le script à chaque passage, et elle est la même sur les
trois écrans.
