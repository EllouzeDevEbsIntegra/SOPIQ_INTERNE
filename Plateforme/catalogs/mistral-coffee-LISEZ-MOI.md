# Mistral Coffee — la carte de démonstration du profil Café

112 articles, 11 rubriques, 4 groupes d'options, et un axe de variante : **le goût de la
chicha**, 14 valeurs.

## Ce que couvre la carte

Café (express, express serré et allongé, double, capucin, direct, café au lait,
américain, noisette, café turc, déca, cappuccino, latte, frappé, glacé) · thés et
infusions (rouge, menthe, amandes, pignons, vert, théière) · chocolat, lait et sahleb ·
jus pressés, milkshakes et smoothies · boissons fraîches (eaux, Garci, Boga, sodas, jus
Délice) · pâtisserie tunisienne et française (baklawa, makroudh, samsa, zlabia, corne de
gazelle, mille-feuille, tiramisu) · crêpes, gaufres et pancakes · salé (paninis, chapati,
croque, omelette, salade) · glaces · **chicha** · **jeux de table** (rami, belote,
chkobba, dominos, dames, échecs).

## Comment le goût de chicha est modélisé

Exactement comme la pâte du Resto : un **axe de variante**. Le caissier prend « Chicha »
et choisit « Double Pomme », « Raisin-Menthe », « Love 66 »… Le goût entre dans le nom
imprimé (« Chicha Double Pomme »), le prix ne change pas d'un goût à l'autre, et le jour
où le patron veut suivre son tabac, il coche le compteur de stock sur le goût — la
mécanique existe déjà, elle a été écrite pour les pâtes.

Les goûts retenus sont ceux qu'on trouve réellement dans les cafés du Maghreb : la double
pomme reste la commande par défaut, la menthe vient ensuite, souvent mélangée, puis le
raisin ; les mélanges de marque (Love 66, Mi Amor, Blue Mist) complètent la liste.

## Les prix

**Ancre : l'express à 1,700 DT**, prix constaté dans un café de catégorie basse en 2026.
Toute la grille est bâtie autour, en gardant les écarts réels du métier — un thé rouge
sous l'express, un jus pressé à trois cafés, une chicha à une tournée. Ils ne se
multiplient donc pas d'un coefficient : chaque poste a été posé pour lui-même.

Pour information, le tarif syndical annoncé en avril 2026 pour les cafés de première
catégorie (express 550, capucin 600, direct 750, thé 450 millimes) est très en dessous de
ce qui se pratique : il n'a pas été retenu.

Ces prix sont une **démonstration cohérente**, pas un tarif à appliquer tel quel. Chaque
client ajuste les siens — et pour une reprise en masse, `mettre-a-jour-prix-pates.sql`
montre la méthode : une liste, un script, un rapport avant/après.

## Charger la carte

    CHARGER_CARTE.bat            (ou catalogs\charger-carte.ps1)

puis choisir `mistral-coffee.json`. Le mode remplacement désactive ce qui n'est pas dans
le fichier et conserve l'historique des ventes.
