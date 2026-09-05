# Integra POS — Inventaire des fonctionnalités (source : code PosCaisse)

Relevé effectué sur la branche `claude/poscaisse-full-app-omsdd4`, dossier `PosCaisse/`
(Vue 3 + Vite, Spring Boot 3 / Java 21, PostgreSQL 16). Tout ce qui suit existe dans le code
et a été vérifié à l'écran dans `screenshots/`. Rien ici n'est une hypothèse.

**Positionnement réel** : caisse tactile pour **fast-food, snack, sandwicherie, pizzeria, café-restaurant, pâtisserie**.
**Il n'y a pas de gestion de tables ni de plan de salle.** Le flux est
`Connexion PIN → Ouverture caisse → Produits → Panier → Encaissement → Tickets → Commande suivante`.
Marché : Tunisie (DT à 3 décimales, fuseau Africa/Tunis, interface en français).

## 1. Caisse (écran caissier)

| Fonction | Détail vérifié | Capture |
|---|---|---|
| Connexion par PIN | Tuiles caissiers colorées + pavé numérique ; mode identifiant / mot de passe pour l'administration | 01 |
| Ouverture de caisse | Choix de la caisse (libre / déjà ouverte par X), fond initial au pavé | — |
| Catégories + Favoris | Rail gauche avec couleur, icône et nombre de produits ; Favoris en premier | 02 |
| Tuiles produits | Prix, catégorie, indicateur « + » si options, badge MENU ; taille S/M/L réglable | 02, 03 |
| Ajout en un toucher | Regroupement automatique des lignes identiques | 03 |
| Options & suppléments | Groupes obligatoires / facultatifs, choix unique / multiple, max, suppléments payants, options répétables (×3), cuisson, « sans oignon »… | 04 |
| Menus / formules | Composition par composant (burger, accompagnement, boisson), suppléments par option, sous-options d'un composant (taille pizza) | 05 |
| Recherche instantanée | Par nom, code ou référence, raccourci F3 | 07 |
| Ligne sélectionnée | − / quantité / + / Options / Remise / Prix / Note / Retirer | 06 |
| Remise | Ligne ou commande, en % ; au-delà du seuil manager, permission requise | 08 |
| Modes de service | Sur place / À emporter / Livraison (livreur obligatoire en livraison) | 06 |
| Client facultatif | Nom, téléphone, recherche ; nécessaire pour le crédit client | 09 |
| Note de commande | Remarque pour la préparation ou la livraison | 09 |
| Encaissement espèces | Boutons 5 / 10 / 20 / 50 DT, montant exact, pavé, **monnaie à rendre calculée à l'instant** | 10 |
| Moyens de paiement | Espèces, carte bancaire, chèque, ticket restaurant, crédit client, autre | 10 |
| Paiement mixte | Plusieurs paiements sur un ticket, liste des paiements, reste à payer | 12 |
| Vente enregistrée | Numéro de ticket `PV01-2026-000001`, total, monnaie à rendre, aperçu du ticket, tickets par destination | 11 |
| Tickets de préparation | Ticket client + tickets cuisine / pizza / boissons routés par destination, copies configurables | 11 |
| Commandes en attente | Référence A-n, heure, caissier, montant, contenu ; reprise ou abandon | 13 |
| Entrée / sortie de caisse | Motif, commentaire, historique de la session | 14 |
| Historique des tickets | Filtres n°, période, statut, caisse, caissier, paiement, montant ; détail ; réimpression DUPLICATA | 15, 16 |
| Menu caissier | Infos session, commandes en attente, mouvements, note, clôture, déconnexion ; raccourcis F2 / F3 / F4 | 17 |
| Clôture de caisse | Récapitulatif (fond, espèces, remboursements, entrées, sorties, carte, autres, tickets, remises, CA), espèces comptées, **écart calculé** | 18, 19, 20 |
| Robustesse | Panier restauré après rafraîchissement, une seule session ouverte par caisse, double validation impossible (idempotence) | — |

## 2. Back-office

| Écran | Contenu vérifié | Capture |
|---|---|---|
| Tableau de bord | CA, tickets, panier moyen, remises, annulations, remboursements ; CA heure par heure ; top produits ; ventes par catégorie ; ventes par caissier ; filtres de période | 21 |
| Tickets | Historique complet multi-critères | 22 |
| Journal de caisse | Chronologie ouverture / ventes / paiements / mouvements / clôtures | 23 |
| Sessions de caisse | Sessions et clôtures par caisse | 24 |
| Clôture journalière | Clôture manager du point de vente, historique | 25 |
| Rapports | 14 rapports (CA journalier, heure, produit, catégorie, caissier, caisse, PDV, paiements, remises, annulations, remboursements, mouvements, clôtures, écarts) + export CSV | 26 |
| Produits & menus | Code, nom, nom court, catégorie, prix, TVA, image, couleur, actif / disponible / favori, options, destinations | 27 |
| Catégories | Ordre, couleur, icône, destination d'impression | 28 |
| Options & suppléments | Groupes, min / max, suppléments, répétables | 29 |
| Disposition POS | Favoris, ordre, taille des tuiles, images | 30 |
| Clients / Livreurs | Fiches, crédit client, comptes livreurs | 31 |
| Utilisateurs / Rôles | 3 rôles système, 22 permissions granulaires modifiables, vérifiées côté serveur | 32, 33 |
| Entreprise & caisses | Entreprise, points de vente, caisses | 34 |
| Moyens de paiement | Activation, ordre, ouverture tiroir | 35 |
| Tickets & impression | Modèle de ticket (58 / 80 mm, police, marges, logo, en-tête, pied, champs) avec **aperçu en direct** ; destinations & copies | 36 |
| Paramètres POS | Modes de service, seuil de remise, boutons espèces, tuiles, TVA, numérotation | 37 |
| Journal d'audit | Connexions, ventes, remises, prix, annulations, remboursements, mouvements, ouvertures / clôtures, paramètres | 38 |

## 3. Import de carte et exploitation

- Import d'une carte complète depuis un fichier JSON (`IMPORT_MENU.bat`) ; mise à jour des prix par ré-import sans doublon.
- Carte réelle fournie en exemple : **NUMBER ONE**, 78 produits, variantes de pain en options obligatoires.
- Lancement en un clic sous Windows (`RESTART_POS.bat`), impression sans dialogue en mode kiosque Chrome / Edge.
- Sauvegarde / restauration, nettoyage du catalogue, remise à zéro avant mise en production.

## 4. Ce qui n'existe PAS (à ne jamais promettre dans la campagne)

- Plan de salle, gestion de tables, réservations.
- Pilotage direct d'imprimante thermique ESC/POS (V1 = impression navigateur ; file `print_job` prête).
- Application mobile, commande en ligne, intégration comptable.
- Multilingue (français seul), export Excel natif (CSV seulement).

## 5. Messages marketing autorisés (déduits de 1 à 3)

1. « Votre caissier encaisse en trois touches : produit, encaisser, valider. »
2. « La monnaie à rendre s'affiche avant même que le client ait fini de payer. »
3. « Espèces, carte, chèque, ticket restaurant, et même un mélange des quatre. »
4. « Un ticket client, un ticket cuisine, un ticket boissons : chacun au bon endroit. »
5. « Clôture de caisse en une minute : théorique, compté, écart. »
6. « Votre journée en un écran : CA, heure de pointe, meilleures ventes, par caissier. »
7. « Chaque remise, chaque annulation, chaque prix modifié est tracé. »
8. « Installé en une journée sur le PC que vous avez déjà. »
