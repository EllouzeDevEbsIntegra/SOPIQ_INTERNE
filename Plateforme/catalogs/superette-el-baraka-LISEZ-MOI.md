# Superette El Baraka — la carte de démonstration du profil Shop

187 articles, 18 rayons, **codes-barres sur tout le catalogue**, prix d'achat et prix de
vente, suivi de stock actif sur 184 articles.

## Les codes-barres : ce qui est vrai, ce qui ne l'est pas

**36 codes sont RÉELS** — relevés dans une base publique de produits (Open Food Facts) sur
des articles vraiment vendus en Tunisie : Safia et Marwa, Boga Cidre, laits Délice et
Vitalait, yaourts Délice et Vitalait, biscuits Saïda (Super Extra, Kaak, Tungo, Major),
Chips-up Céréalis, couscous Warda, thon et sardines Sidi Daoud, harissa Sicam et Jouda,
cafés Bondin et Ben Yedder, chocolat Club. Ils commencent par **619**, le préfixe GS1 de la
Tunisie.

**151 codes sont INTERNES**, construits sur le préfixe **2**. Ce préfixe est réservé par la
norme à l'usage interne des magasins : il ne peut entrer en conflit avec aucun produit du
commerce. Chaque code porte une clé de contrôle valide — un lecteur les accepte comme
n'importe quel autre.

Ce choix est délibéré. Inventer des codes en 619 aurait produit l'inverse de ce qu'on
cherche : des codes qui ont l'air authentiques, qui appartiennent peut-être déjà à un autre
fabricant, et qui fausseraient un inventaire sans que personne ne comprenne pourquoi.

**À la mise en service**, la boutique scanne ses propres articles : le code lu remplace le
code interne, rayon par rayon. Compter une dizaine de minutes par rayon.

## Ce que la carte contient

Eaux · boissons gazeuses (Boga, Coca, Fanta, Sprite, Schweppes) · jus · laits et yaourts ·
fromages et beurre · biscuits et gaufrettes · chocolats et confiserie · chips et snacks ·
épicerie sèche (couscous, pâtes, riz, semoule, sucre, légumes secs) · conserves (thon,
sardines, harissa, tomate, olives) · huiles et condiments · café, thé et petit-déjeuner ·
hygiène et entretien · bébé · **tabac** · **recharges téléphoniques** · **vape** ·
dépannage (piles, ampoules, cahier, stylo).

## Les prix

Prix de vente et **prix d'achat** sont renseignés sur chaque article : c'est ce qui permet
au gérant de voir sa marge réelle, rayon par rayon. Ils reflètent le marché tunisien de
2026 — le tabac suit les tarifs officiels (Cristal 4,100 · 20 Mars 4,500 · Marlboro 10,000),
le reste est une grille cohérente à ajuster à la boutique.

## Ce qui n'est pas suivi en stock

Trois articles : les deux **recharges Light** (un rechargement direct ne quitte pas le
rayon, il n'y a rien à compter) et le **sac plastique**. C'est la démonstration du mode
`partiel` : chaque article décide.

## Charger la carte

    CHARGER_CARTE.bat        → choisir superette-el-baraka.json

Puis, dans les réglages : `catalog.barcode.enabled = true`, `stock.mode = partiel`,
`stock.rupture = refuser`, `stock.entree = achat`.
