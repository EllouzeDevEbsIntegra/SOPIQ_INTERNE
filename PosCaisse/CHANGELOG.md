# Changelog

## 1.0.0 — 2026-09-04

- Structure initiale du projet (backend Spring Boot 3.5 / Java 21, frontend Vue 3 / Vite, PostgreSQL 16, Flyway).
- Backend core : schéma V1, entités, sécurité JWT + PIN, rôles/permissions, catalogue, sessions de caisse, ventes (checkout idempotent, attente/reprise, annulation, remboursement), journal, mouvements, clôtures, impression (rendu 58/80 mm, routage, jobs), rapports, audit, jeu de démonstration.
- Frontend POS tactile : connexion PIN, ouverture de caisse, écran POS (favoris, catégories, tuiles, recherche, panier), options/menus, paiement mixte + rendu, tickets + impression, commandes en attente, mouvements de caisse, clôture, historique des tickets.
- Back-office : dashboard, tickets, journal, sessions, clôture journalière, rapports + CSV, produits/menus, catégories, options, disposition POS/favoris, clients, utilisateurs, rôles, entreprise/PDV/caisses, moyens de paiement, tickets & impression, paramètres, audit.
- Corrections après tests : ventes espèces nettes en clôture, erreurs 400 sur paramètres invalides, style de tuile menu, pavé numérique (valeur initiale remplacée), débordement du panier en 768 px, composition de menu (sous-options seulement si obligatoires), aperçu ticket (transaction).
- Tests unitaires + scénario d'intégration, scripts Windows/Linux, documentation.
