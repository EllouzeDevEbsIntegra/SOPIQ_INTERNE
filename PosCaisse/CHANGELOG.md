# Changelog

## 1.0.0 — 2026-09-04

- Structure initiale du projet (backend Spring Boot 3.5 / Java 21, frontend Vue 3 / Vite, PostgreSQL 16, Flyway).
- Backend core : schéma V1, entités, sécurité JWT + PIN, rôles/permissions, catalogue, sessions de caisse, ventes (checkout idempotent, attente/reprise, annulation, remboursement), journal, mouvements, clôtures, impression (rendu 58/80 mm, routage, jobs), rapports, audit, jeu de démonstration.
- Frontend POS tactile : connexion PIN, ouverture de caisse, écran POS (favoris, catégories, tuiles, recherche, panier), options/menus, paiement mixte + rendu, tickets + impression, commandes en attente, mouvements de caisse, clôture, historique des tickets.
- Back-office : dashboard, tickets, journal, sessions, clôture journalière, rapports + CSV, produits/menus, catégories, options, disposition POS/favoris, clients, utilisateurs, rôles, entreprise/PDV/caisses, moyens de paiement, tickets & impression, paramètres, audit.
- Corrections après tests : ventes espèces nettes en clôture, erreurs 400 sur paramètres invalides, style de tuile menu, pavé numérique (valeur initiale remplacée), débordement du panier en 768 px, composition de menu (sous-options seulement si obligatoires), aperçu ticket (transaction).
- Tests unitaires + scénario d'intégration, scripts Windows/Linux, documentation.
- Import de carte : `POST /api/catalog/import` (permission `PRODUCTS_MANAGE`), scripts `IMPORT_MENU.bat` / `import-menu.sh`, et carte réelle **NUMBER ONE** dans `catalogs/number-one.json` (78 produits, variantes de pain en options obligatoires). Le mode remplacement supprime ce qui n'a jamais été vendu et désactive le reste, l'historique des ventes est préservé.
- Script unique de redémarrage (`RESTART_POS.bat` / `restart.sh`) : arrêt, `git pull`, base, recompilation si nécessaire, démarrage et ouverture du navigateur en un double-clic ; le script s'exécute depuis une copie temporaire pour survivre à sa propre mise à jour. Préparation de la base factorisée dans `_ensure_db.bat`.
- Refonte du design : système de tokens (neutres chauds, accent unique, bordures nettes, chiffres tabulaires), jeu d'icônes vectorielles remplaçant les emoji de l'interface, écran POS repensé pour exploiter toute la largeur d'un 15 pouces (rail de catégories, grille fluide en `clamp()`, panier redessiné), encaissement, connexion, ouverture et clôture de caisse et back-office remis au même niveau ; point d'entrée public `/api/public/branding` pour afficher l'enseigne avant connexion.
- Passe robustesse : brouillon de panier persistant (refresh), raccourcis Entrée, test de concurrence multi-caisses, aperçu ticket dans l'écran de fin de vente.
