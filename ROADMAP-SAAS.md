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

## Questions ouvertes (posées le 08/09, réponses à consigner ici)

1. **Un seul code, ou un code par verticale ?** Trois copies divergent en trois mois ; la
   plateforme finale suppose au contraire *un* code et un profil métier. À trancher.
2. **Une base par client, ou une base commune cloisonnée ?**
3. **Où tourne l'application ?** Postes autonomes sous licence (comme aujourd'hui), ou
   serveur central et caisses dans le navigateur ?

## Ce qui est vrai des codes-barres tunisiens

Le préfixe GS1 de la Tunisie est **619**. Les codes de la démonstration seront soit des
codes réellement établis, soit des codes construits sur ce préfixe avec une clé de
contrôle valide et **marqués comme démonstration** : un code inventé qui se ferait passer
pour authentique ferait rater un inventaire chez le client. La boutique rescanne ses
propres produits à la mise en service, c'est l'affaire de quelques minutes par rayon.
