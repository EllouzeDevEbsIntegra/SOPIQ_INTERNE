# Les cartes de démonstration, une par métier

Une carte de démonstration n'est pas un jeu d'essai : c'est **l'argument de vente**. Le
client doit y reconnaître son magasin dès la première minute — ses produits, ses prix, ses
mots. C'est la différence entre une démonstration qui emporte la décision et une
démonstration qu'il faut excuser.

| Fichier | Métier | Articles | Ce qui la caractérise |
|---|---|---:|---|
| `number-one-2026.json` | Resto | 117 | variantes de pâte, stock par pâte *(carte d'un client réel — à remplacer par une carte neutre avant toute vente)* |
| `mistral-coffee.json` | Café | 112 | **goûts de chicha** en variante, jeux de table facturés |
| `superette-el-baraka.json` | Shop | 187 | **codes-barres**, prix d'achat, stock par article |
| `dar-halwa.json` | Pâtisserie | 71 | **vente au kilo**, commandes de fête, viennoiserie |
| `nour-parfums.json` | Parfumerie | 76 | **contenances** (30/50/100/200 ml) en variante, codes-barres |
| `style-boutique.json` | Prêt-à-porter | 65 | **tailles** en variante, codes-barres, prix d'achat |

## Comment les charger

    CHARGER_CARTE.bat        → choisir le fichier

Le mode remplacement désactive ce qui n'est pas dans le fichier et **conserve l'historique
des ventes** : un article déjà vendu n'est jamais supprimé, il est désactivé.

## Les codes-barres

Seules les cartes Shop, Parfumerie et Prêt-à-porter en portent — les trois métiers qui
scannent. Le réglage, lui, existe pour tout le monde : un café qui veut scanner ses
bouteilles coche la case dans *Paramètres → Métier*.

Dans la carte Shop, **36 codes sont réels** (relevés en base publique sur de vrais produits
tunisiens, préfixe 619) ; tous les autres codes, dans les trois cartes, sont construits sur
le **préfixe 2, réservé à l'usage interne des magasins**. Ils ne peuvent entrer en conflit
avec aucun produit du commerce, et se remplacent au scan à la mise en service.

## Ce que ces cartes ont appris sur le logiciel

Trois manques repérés en les construisant, notés pour ne pas être oubliés :

1. **Taille × couleur.** Un article ne porte qu'un axe de variante. Le prêt-à-porter en
   demande deux, avec un stock par croisement — un T-shirt noir en L n'est pas un T-shirt
   blanc en L. En attendant, la couleur est dans le nom et la taille est l'axe : cela
   marche, mais le stock ne distingue pas les couleurs.
2. **Vente au poids.** La pâtisserie vend au kilo. Les prix sont donc au kilo et la
   quantité se saisit en décimal, mais rien ne dit encore à l'écran que « 0,750 » veut dire
   750 grammes, et aucune balance n'est branchée.
3. **Pointures.** Les chaussures n'utilisent pas l'axe des tailles de vêtement : un
   deuxième axe réglerait les deux d'un coup.
