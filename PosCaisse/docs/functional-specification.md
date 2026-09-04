# Spécification fonctionnelle — PosCaisse

## Cible
Fast-foods, snacks, sandwicheries, pizzerias, cafés-restaurants, pâtisseries/snacking. **Aucune gestion de tables** : le flux est `PRODUITS → PANIER → ENCAISSEMENT → TICKETS → COMMANDE SUIVANTE`.

## Acteurs et rôles
| Rôle | Périmètre |
|------|-----------|
| Caissier | ouvrir sa caisse, vendre, remise ≤ seuil, mettre en attente, mouvements, réimprimer, consulter les tickets, clôturer sa caisse |
| Manager | caissier + remises élevées, prix, annulation/remboursement, catalogue, rapports, dashboard, clôture journalière, audit |
| Administrateur | tout, y compris utilisateurs, rôles, paramètres, entreprise |
Les permissions (22) sont modifiables par rôle et vérifiées côté serveur.

## Parcours caissier
1. **Connexion** : tuile + PIN (ou PIN seul). Administration par identifiant/mot de passe.
2. **Ouverture de caisse** : choix de la caisse disponible, fond initial. Une caisse déjà ouverte est signalée (« Cette caisse possède déjà une session ouverte (par X) »).
3. **POS** : catégories à gauche (Favoris en premier), tuiles produits, panier à droite avec SOUS-TOTAL / REMISE / TOTAL et gros bouton ENCAISSER.
   - Toucher = ajout immédiat (regroupement des lignes identiques). Produit avec option obligatoire ou menu → fenêtre de composition.
   - Ligne sélectionnée : − / quantité / + / Options / Remise / Prix / Note / Supprimer.
   - Appui long sur une tuile : options, ou basculer disponible/indisponible.
   - Recherche par nom / code / référence. Modes de service. Client facultatif (nom, téléphone, recherche).
   - Mettre en attente (référence A-n) → écran des commandes en attente (référence, heure, caissier, montant, client) → reprise / abandon.
4. **Encaissement** : moyens configurables, boutons espèces 5/10/20/50 + MONTANT EXACT, pavé, « À PAYER / REÇU / À RENDRE » instantané, paiement mixte (liste des paiements), VALIDER (désactivé tant que le reste > 0 et pendant l'enregistrement).
5. **Après validation** : vente + lignes + options + paiements enregistrés en une transaction, numéro attribué, tickets générés (client + préparation), écran « Vente enregistrée » avec À RENDRE et bouton IMPRIMER, puis NOUVELLE COMMANDE (panier vidé).
6. **Caisse** : entrée/sortie (motif, montant, commentaire), historique de la session.
7. **Clôture** : récapitulatif (fond, espèces, remboursements, entrées, sorties → théorique ; carte, autres, tickets, remises, CA), saisie des espèces comptées, écart, commentaire.

## Règles de gestion
- Prix TTC ; TVA optionnelle (`tax.enabled`) calculée dans le prix.
- Remise ligne ou commande en % (ou montant via API). Remise > seuil (`discount.highThresholdPercent`) ⇒ permission `DISCOUNT_HIGH`. Remise max par utilisateur possible.
- Paiement : somme des montants = total ; un excédent n'est accepté qu'en espèces (rendu). Paiement insuffisant refusé.
- Numérotation : `{POS}-{YYYY}-{SEQ:6}` par défaut ; unique en multi-caisses.
- Annulation post-paiement : statut CANCELLED + remboursement du restant + motif + audit ; jamais de suppression.
- Remboursement partiel : montant ≤ restant ; statut PARTIALLY_REFUNDED puis REFUNDED.
- Clôture de caisse impossible s'il reste des commandes en attente sur la session ; clôture journalière impossible s'il reste une caisse ouverte ; une seule clôture par jour et point de vente.
- Produit indisponible : reste au catalogue, refusé à la vente (frontend et backend).

## Back-office
Dashboard, tickets, journal, sessions, clôture journalière, rapports (CA journalier, heure, produit, catégorie, caissier, caisse, point de vente, paiements, remises, annulations, remboursements, mouvements, clôtures, écarts) + CSV, catalogue complet, disposition POS (favoris, ordre, taille des tuiles, images), clients, utilisateurs, rôles, entreprise/PDV/caisses, moyens de paiement, modèle de ticket + destinations, paramètres POS, audit.
