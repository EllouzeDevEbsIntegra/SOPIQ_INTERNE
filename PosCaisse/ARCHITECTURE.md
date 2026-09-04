# Architecture — PosCaisse

## Vue d'ensemble

```
[Navigateur tactile]  Vue 3 + Pinia + Vue Router + Axios  (frontend/)
        │  HTTP JSON  /api/**  (JWT Bearer)
[Backend]  Spring Boot 3.5 / Java 21  (backend/)
        │  JPA / Hibernate + JDBC (rapports)
[PostgreSQL 16]  schéma géré par Flyway (V1__init.sql)
```

## Décisions structurantes

1. **Panier côté frontend, validation côté backend.** Chaque toucher sur un produit modifie uniquement le store Pinia (`stores/cart.js`). Le backend re-calcule intégralement les prix (`PricingService`) et re-valide produits, disponibilité, options (min/max/obligatoire), composition des menus, remises et permissions lors du `POST /api/pos/checkout`. Le frontend ne fait jamais foi.
2. **Montants en `BigDecimal` scale 3 / `NUMERIC(14,3)`.** Aucun float. Côté navigateur, `utils/money.js` arrondit systématiquement à 3 décimales et l'affichage suit la locale `fr-FR` (`8,500 DT`).
3. **Idempotence de l'encaissement.** Le frontend génère un `clientRef` (UUID) par commande ; `sale_order.client_ref` est UNIQUE. Un double toucher renvoie la vente existante au lieu d'en créer une seconde. Le bouton est en outre désactivé pendant l'appel.
4. **Numérotation sans doublon multi-caisses.** `document_sequence` est verrouillée par `SELECT … FOR UPDATE` (`@Lock(PESSIMISTIC_WRITE)`) dans la transaction de vente ; `ticket_number` est UNIQUE. Le format est paramétrable (`{POS}-{YYYY}-{SEQ:6}`) et le compteur est scoppé par préfixe résolu (reset annuel naturel).
5. **Une session ouverte par caisse.** Index unique partiel `ux_register_session_open ON register_session(register_id) WHERE status='OPEN'` + contrôle applicatif avec message humain (409).
6. **Intégrité financière.** Une vente encaissée n'est jamais supprimée : statuts `PAID → CANCELLED / PARTIALLY_REFUNDED / REFUNDED`, entité `refund`, journal de caisse (`register_journal`) et `audit_log`. Les commandes `HELD` (en attente) sont les seules supprimables (jamais numérotées, jamais payées).
7. **Journal de caisse matérialisé.** Chaque événement (ouverture, vente, paiement, annulation, remboursement, entrée/sortie, clôture) écrit une ligne dans `register_journal` : filtrage simple, aucun UNION complexe à l'exécution.
8. **Impression découplée.** Le rendu produit du **texte monospace** calibré 32/42 colonnes (58/80 mm). Le routage (`PrintService`) crée un `print_job` par destination (ticket client + une par destination de préparation concernée, N copies). V1 : impression navigateur via iframe ; l'état `PENDING/PRINTED` permet un agent ESC/POS ultérieur sans changer le modèle.
9. **Sécurité.** JWT HS256 stateless (`JwtAuthFilter`), BCrypt (force 8 pour rester rapide sur PIN), autorités = permissions du rôle ; `@PreAuthorize` sur les contrôleurs + contrôles métier fins dans les services (remise > seuil, remise max par utilisateur, annulation manager…).
10. **Rapports en SQL natif** (`NamedParameterJdbcTemplate`) : agrégations directement dans PostgreSQL, fuseau `Africa/Tunis` pour les regroupements par jour/heure.
11. **Multi-points de vente** : `company → point_of_sale → register → register_session`, toutes les ventes portent entreprise / point de vente / caisse / session / caissier.
12. **i18n** : dictionnaire `utils/i18n.js` (français) prêt à recevoir arabe/anglais ; aucun libellé métier en dur dans les enums affichées.

## Backend — packages

| Package | Rôle |
|---------|------|
| `domain` | entités JPA + enums |
| `repository` | Spring Data JPA (une interface par agrégat) |
| `service` | métier : `OrderService` (checkout/hold/cancel/refund/search), `RegisterSessionService`, `ClosureService`, `CatalogService`, `AdminService`, `PricingService`, `TicketNumberService`, `SettingsService`, `JournalService`, `AuthService` |
| `printing` | `ReceiptRenderer` (texte 58/80 mm), `PrintService` (routage, jobs, modèles) |
| `reports` | `ReportService` (dashboard + 14 rapports + CSV) |
| `web` | contrôleurs REST (DTO uniquement) |
| `dto` | records de requêtes/réponses (validation Jakarta) |
| `security` | JWT, filtre, `SecurityConfig`, `CurrentUser` |
| `exception` | `BusinessException`, `ApiError`, `GlobalExceptionHandler` (messages humains) |
| `audit` | `AuditService` |
| `bootstrap` | `DemoDataSeeder` (rôles/paiements/destinations + démo) |

## Système de design

Cible principale : écran tactile 15 pouces (1366 × 768) exploité sur toute la largeur ; vérifié aussi en 1920 × 1080, 1024 × 700 et 800 × 600.

- **Palette** : neutres chauds (`--ink`, `--canvas`, `--surface`, `--line`) plutôt que le gris bleuté par défaut, **un seul accent** vermillon `#C8441C` pour la sélection et la marque, vert `#15784A` réservé à l'encaissement, rouge/ambre/bleu pour les états. Aucune couleur n'est utilisée décorativement : la couleur porte une information (catégorie, état, action).
- **Typographie** : pile système Segoe UI Variable, échelle resserrée, `font-variant-numeric: tabular-nums` sur tous les montants (les colonnes de chiffres restent alignées), majuscules réservées aux étiquettes courtes (`.eyebrow`).
- **Formes** : rayons courts (4 → 18 px), **bordures 1 px plutôt qu'ombres diffuses**, ombres réservées aux éléments flottants (modales, bouton d'encaissement).
- **Icônes** : jeu vectoriel maison (`components/common/Icon.vue`, contour 24×24, trait 1.75) — aucun emoji dans l'interface de l'application ; les emoji restent possibles côté données pour les icônes de catégorie choisies par le commerçant.
- **Densité tactile** : cibles ≥ 42 px, pavé numérique 54 px, tuiles produits dimensionnées en `clamp()` sur la largeur de fenêtre (la grille remplit l'espace disponible quel que soit l'écran), panier `clamp(322px, 23.5vw, 412px)`.
- **Hiérarchie du POS** : le TOTAL et le bouton ENCAISSER sont les deux éléments les plus contrastés de l'écran ; tout le reste (rail de catégories, tuiles, panier) est volontairement calme.

## Frontend — organisation

```
src/api        http.js (axios, erreurs humaines, 401 → logout), index.js (tous les endpoints)
src/stores     auth (JWT, session ouverte), catalog, cart, ui (toasts, confirmations)
src/components common/ (Modal, NumPad réutilisable, BarChart, PeriodPicker)  pos/ (tuiles, panier, options/menus, paiement, tickets, attente, mouvements, détail ticket)
src/views      LoginView, pos/ (OpenRegister, Pos, CloseRegister, Tickets), admin/ (17 écrans)
src/layouts    AdminLayout
src/utils      money (3 décimales), dates (Africa/Tunis), i18n
src/composables usePrinter (impression iframe), useApi (busy + erreurs)
```
