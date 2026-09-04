# État du projet — PosCaisse

Dernière mise à jour : 2026-09-04

## Terminé ✅

- PostgreSQL + Flyway (`V1__init.sql`, 27 tables, index, contraintes) — schéma validé par Hibernate (`ddl-auto: validate`)
- Authentification JWT : PIN (tuiles caissiers ou PIN seul), identifiant/mot de passe, BCrypt, `/api/auth/me`
- Rôles ADMIN / MANAGER / CAISSIER + 22 permissions granulaires, éditables, contrôlées côté backend
- Entreprise / points de vente / caisses / utilisateurs (CRUD back-office)
- Ouverture de caisse avec fond, une seule session ouverte par caisse (message humain), reprise de session au rechargement
- Catalogue : catégories (ordre, couleur, icône, destination), produits (code, référence, nom court, image, couleur, ordre, actif, disponible, favori, TVA, destinations), options/suppléments (groupes obligatoire/facultatif, unique/multiple, min/max, supplément), menus/formules (composants, quantités, suppléments par option), disponibilité en 1 toucher
- POS tactile : favoris, catégories, tuiles (S/M/L), recherche instantanée, panier local instantané, +/−, quantité par pavé, options, notes, remise ligne/commande (seuil manager + remise max utilisateur), prix (permission), suppression ligne, modes de service, client facultatif, note de commande, appui long = options / indisponible, raccourcis clavier
- Commandes en attente / reprise / abandon (persistées, référence A-n)
- Encaissement : espèces (5/10/20/50, montant exact, rendu instantané), carte, chèque, ticket restaurant, autre, paiement mixte, validation transactionnelle, idempotence, numérotation configurable sans doublon
- Tickets : client + préparation (routage produit/catégorie → destination), copies par destination, 58/80 mm, modèle configurable (en-tête, pied, champs, séparateur, police, marges, logo) avec aperçu live, impression navigateur, réimpression DUPLICATA, `print_job`
- Journal de caisse (ouverture, ventes, paiements, annulations, remboursements, entrées, sorties, clôtures) filtrable
- Mouvements de caisse (entrée/sortie, motif, commentaire)
- Clôture de caisse (théorique / réel / écart, récapitulatif complet), clôture journalière manager avec historique
- Annulation de ticket encaissé (motif, remboursement, permission, audit), remboursement partiel/total
- Historique des tickets (numéro, période, caisse, caissier, montant, paiement, statut) + détail + actions
- Dashboard réel (CA, tickets, panier moyen, heure par heure, jour, catégories, top produits, caissiers, caisses, paiements, modes) avec filtres de période
- 14 rapports + export CSV
- Paramètres : entreprise, PDV, caisses, utilisateurs, rôles, catégories, produits, menus, options, paiements, TVA, tickets, destinations, numérotation, POS (modes, seuil remise, boutons espèces, tuiles, images)
- Audit (connexion, ventes, remises, prix, annulations, remboursements, mouvements, ouverture/clôture, paramètres, catalogue, utilisateurs)
- Gestion d'erreurs homogène (`ApiError`), messages humains dans l'interface
- Scripts `START_POS.bat`, `STOP_POS.bat`, `BUILD_POS.bat`, `start.sh`, `stop.sh`, `docker-compose.yml`, `.env.example`
- Build : `mvn package` OK, `npm run build` OK ; backend sert `frontend/dist` (mode production sur un seul port)

## Partiel ⚠️

- Impression physique : V1 = impression navigateur (iframe, N copies, taille papier). L'architecture `print_job` est prête pour un agent ESC/POS (voir `docs/printing.md`) mais aucun pilote thermique n'est inclus.
- Remboursement partiel : par montant (pas par sélection de lignes).
- Export Excel : CSV uniquement (UTF-8 BOM, séparateur « ; », s'ouvre dans Excel FR).
- Multilingue : structure i18n prête, seul le français est fourni.
- Images produits : stockées en data-URI dans PostgreSQL (limite 400 Ko) — suffisant pour une V1, un stockage fichier serait préférable pour de gros catalogues.

## Restant / améliorations proposées

Voir `TODO.md`.

## Bugs connus

- Aucun bug bloquant connu au moment de la livraison.

## Tests effectués

- **Unitaires (JUnit 5)** : `PricingServiceTest` (8), `TicketNumberFormatTest` (3), `ReceiptRendererTest` (3) — `mvn test` → 14 tests OK.
- **Intégration (Spring Boot + PostgreSQL, `POSCAISSE_IT=true`)** : `PosIntegrationTest` (5) — login PIN, ouverture/double ouverture, vente 2 Cheeseburgers + fromage + 2 Frites + 2 Coca payée 50 DT (rendu 22), double soumission idempotente, paiement mixte 32,500 (20 espèces + 12,500 carte), paiement insuffisant refusé, remise 30 % refusée au caissier, API `/api/users` refusée (403) au caissier et au manager, annulation refusée au caissier, sortie 20 DT, remboursement 5 DT manager, clôture avec écart −3,000.
- **Scénario navigateur (Playwright, Chromium)** : connexion PIN Ahmed → ouverture CAISSE 01 fond 100 → Burgers → 2 Cheeseburgers → supplément fromage → Frites → Coca → quantité → mise en attente → reprise → ENCAISSER → espèces 50 → rendu 22,000 → validation → vente PostgreSQL → tickets client + cuisine + boissons → nouvelle commande → paiement mixte 32,500 → menu burger → sortie de caisse 20 → historique → détail → réimpression → clôture (écart calculé) ; 0 erreur console. Back-office : 17 écrans chargés sans erreur, création produit + indisponibilité, modèle ticket 58 mm, création utilisateur, aperçu clôture journalière. Responsive : 1920×1080, 1366×768, 1024×700, 800×600 (panier en tiroir).
