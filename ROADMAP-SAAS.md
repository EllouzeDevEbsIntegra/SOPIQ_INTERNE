# Feuille de route — de PosCaisse (Resto) à une plateforme SaaS multi-métiers

> Consigne posée le 08/09/2026 par le propriétaire du projet, à tenir sans avoir à la
> redemander. Ce fichier est la référence : ce qui n'y est pas écrit n'a pas été décidé.

## Règle n° 1 — le figé

**`PosCaisse/` est la verticale 1, RESTO. Elle est FIGÉE.** Elle tourne chez un client
réel (NUMBER ONE, Chihia). On n'y touche plus : ni refonte, ni « petite amélioration »,
ni renommage. Les seules modifications admises sont une correction d'anomalie demandée
par le client, et elles restent dans cette racine.

Chaque verticale terminée passe dans le même état : **finie = figée**.

## Objectif 1 — verticale 2 : CAFÉ

Une racine séparée, même application, même principe, mêmes manipulations. Ce qui change
est la **base de démonstration**, pas le fonctionnement.

- Enseigne de démonstration : « Mistral Coffee » (nom de travail).
- La carte d'un café tunisien, recherchée sérieusement, pas inventée : express, capucin,
  direct, café turc, américain, thé (à la menthe, aux amandes, aux pignons), infusions,
  jus et boissons fraîches, pâtisseries d'accompagnement, chicha **avec ses goûts**
  (pomme double, menthe, raisin, mélasse…), et les **jeux de cartes facturés** — rami,
  belote, chkobba, dominos — qui se louent à la table dans les cafés tunisiens.
- Livrable : une démonstration montrable à un client qui tient un café.

## Objectif 2 — verticale 3 : SHOP (alimentation générale)

Même application, mais deux différences de fond :

1. **Code-barres.** Chaque article porte le sien, la vente se fait au scanner (lecteur
   clavier), la recherche par code doit être immédiate.
2. **Stock, en option par article ou par boutique** — un paramètre, pas une règle. Quand
   il est actif, l'article doit être **entré en stock à l'achat** avant de pouvoir être
   vendu.

Base de démonstration : produits **tunisiens** (pas d'étranger), au plus près de ce que
le client vendra réellement — biscuits, eaux, chocolats, boissons gazeuses, tabac,
recharges téléphoniques (carte et « light »), yaourts, vape, recharges et puffs. Avec
leurs codes-barres partout où ils peuvent être établis. Objectif affiché : que la démo
couvre ~90 % de ce que le client retrouvera dans sa boutique.

## Verticales suivantes, même moule

Pâtisserie, prêt-à-porter, parfumerie, et ce que le marché demandera.

## Objectif final — la plateforme SaaS

Une seule offre commerciale, plusieurs métiers. Ce qu'il faut construire :

- **Back-office éditeur** (le nôtre) : clients, abonnements, **licences**, utilisateurs et
  connexions, facturation et **suivi des paiements** — *sans paiement en ligne pour le
  moment* —, versions et mises à jour des postes.
- **Choix du métier à la souscription** : on crée le client, on lui affecte le module
  (Shop, Resto, Café, Pâtisserie, Vêtement…), et son espace part avec la base de
  démonstration correspondante.
- **Livraison au client** : identifiants envoyés, il ouvre son back-office, trouve les
  données de démonstration déjà en place, les modifie — ou repart de zéro d'un bouton.
- **Sécurité : priorité absolue.** Cloisonnement des données entre clients, mots de passe,
  sessions, journal d'audit, sauvegardes.
- Et pour le client final, l'application telle qu'elle existe déjà : caisse tactile +
  back-office, comme la verticale Resto.

## Les trois décisions d'architecture (prises le 08/09)

1. **Un seul code, le métier est un PROFIL.** Pas de copie par verticale. Un profil
   apporte ses réglages, sa carte de démonstration et les écrans qu'il active ; le Café
   et le Shop sont deux profils, pas deux logiciels.

   *Conséquence, puisque la verticale Resto est figée :* `PosCaisse/` reste ce qu'elle est,
   le produit livré à NUMBER ONE, et **on en tire UNE fois une copie** qui devient le code
   vivant de la plateforme. À partir de là, un seul code évolue ; `PosCaisse/` ne bouge
   plus que pour une anomalie de ce client.

2. **Une base par client.** Cloisonnement total : une restauration ne touche qu'un client,
   et une erreur de requête ne peut pas faire fuir les données d'un autre. Le back-office
   éditeur crée la base à la souscription et la garnit du profil choisi.

3. **Serveur central, caisses dans le navigateur.** Rien à installer chez le client, mises
   à jour immédiates.

   *Risque à traiter, pas à ignorer :* une coupure d'internet arrête une caisse en plein
   service. Pour un fast-food aux heures de pointe, c'est inacceptable tel quel. À prévoir
   dans la conception : reprise de session sans perte du panier, tolérance aux coupures
   courtes, et la possibilité de retomber sur une installation locale pour les clients qui
   vendent en continu (le paquet autonome existe déjà, il ne demande qu'à être réutilisé).

## Ce qu'un profil décide — le paramétrage

Un métier ne change pas le logiciel, il change des **réglages**. Voici ceux qui font la
différence entre les verticales ; tous doivent être modifiables par client, parce que deux
boutiques du même métier ne travaillent jamais pareil.

### Code-barres

| Réglage | Ce qu'il fait | Shop | Vêtement | Resto | Café | Pâtisserie |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `barcode.enabled` | champ code-barres sur la fiche, lecture au scanner en caisse | ✔ | ✔ | — | — | — |
| `barcode.required` | refuse d'enregistrer un article sans code | option | option | — | — | — |
| `barcode.autoAdd` | un scan ajoute directement au panier, sans confirmation | ✔ | ✔ | — | — | — |
| `barcode.unknownAsk` | un code inconnu propose de créer l'article sur-le-champ | ✔ | ✔ | — | — | — |

### Stock

Le stock n'est pas un interrupteur unique : c'est **trois** questions distinctes.

| Réglage | Valeurs | Ce que ça change |
|---|---|---|
| `stock.mode` | `aucun` · `partiel` · `total` | `partiel` = chaque article décide (le pain oui, le café non). C'est le cas le plus fréquent, et le défaut. |
| `stock.porte` | `article` · `valeur de variante` · `déclinaison` | Le Resto compte la **pâte** (valeur de variante), le Shop compte l'**article**, le Vêtement compte la **taille × couleur**. |
| `stock.rupture` | `refuser` · `avertir` · `laisser passer` | Un fast-food refuse ; une boutique préfère parfois vendre et régulariser. |
| `stock.entree` | `achat` · `saisie libre` | Le Shop entre son stock par un **achat** (fournisseur, prix d'achat, quantité) ; le Resto saisit à la main ce qui arrive du frigo. |
| `stock.remiseAZero` | `jamais` · `à la clôture` | La pâte ne se garde pas d'un jour sur l'autre ; une caisse de biscuits, si. |

### Le reste, métier par métier

- `service.modes` — sur place, à emporter, livraison, **table** (Café et Resto ouvrent des
  tables et diffèrent l'addition ; un Shop encaisse au comptoir).
- `print.destinations` — cuisine, bar, **chicha**, aucune. Le Shop n'imprime qu'un ticket
  client.
- `variant.axe` — le nom par défaut de l'axe : Pâte, Goût, Taille, Parfum…
- `pricing` — devise, décimales (3 pour le dinar), prix TTC ou HT, taux de TVA par défaut.
- `catalog.demo` — la carte de démonstration installée à la souscription.
- `caisse` — fond de caisse obligatoire, clôture journalière, marge bénéficiaire en %.

### Un écart à traiter avant la verticale Vêtement

Aujourd'hui **un article porte au plus UN axe de variante** (la pâte, le goût). Le
prêt-à-porter en demande **deux** : taille × couleur, avec un stock par croisement. Ce
n'est pas un réglage, c'est un chantier — à mener avant de vendre ce profil, et sans
casser les deux axes uniques déjà en service.

## Ordre de marche

1. Créer la racine du code vivant, à partir du code figé — **sans toucher à `PosCaisse/`**.
2. Le profil **Café** et sa base de démonstration « Mistral Coffee ».
3. Le profil **Shop** : code-barres, stock optionnel entré à l'achat, et sa base de
   démonstration tunisienne.
4. Le back-office éditeur : clients, abonnements, licences, utilisateurs, facturation
   (sans paiement en ligne), versions, sécurité et cloisonnement.
5. Les profils suivants : pâtisserie, prêt-à-porter, parfumerie.

## Ce qui est vrai des codes-barres tunisiens

Le préfixe GS1 de la Tunisie est **619**. Les codes de la démonstration seront soit des
codes réellement établis, soit des codes construits sur ce préfixe avec une clé de
contrôle valide et **marqués comme démonstration** : un code inventé qui se ferait passer
pour authentique ferait rater un inventaire chez le client. La boutique rescanne ses
propres produits à la mise en service, c'est l'affaire de quelques minutes par rayon.
