# Modèle de données (PostgreSQL) — `backend/src/main/resources/db/migration/V1__init.sql`

Tous les montants : `NUMERIC(14,3)`. Horodatages : `TIMESTAMPTZ`. Identifiants : `BIGSERIAL`.

| Table | Rôle | Points clés |
|-------|------|-------------|
| `company` | entreprise | devise, symbole, décimales, fuseau, logo (data-URI) |
| `point_of_sale` | points de vente | `code` unique, FK company |
| `register` | caisses / terminaux | unique (`point_of_sale_id`, `code`) |
| `role`, `role_permission` | rôles et permissions (enum `Permission`) | rôles système non supprimables |
| `app_user` | utilisateurs | `password_hash`, `pin_hash` (BCrypt), `max_discount_percent`, `point_of_sale_id` |
| `register_session` | sessions de caisse | index unique partiel `WHERE status='OPEN'`, totaux de clôture, `version` (optimiste) |
| `category` | catégories | couleur, icône, ordre, destination d'impression par défaut |
| `product` | produits & menus | `product_type` SIMPLE/MENU, prix, TVA, image, favori, disponible |
| `product_print_destination` | routage produit → destination | |
| `modifier_group`, `modifier` | options / suppléments | obligatoire, multiple, min, max, `price_delta` |
| `product_modifier_group` | groupes proposés par produit | ordre |
| `menu_component`, `menu_component_product` | composition des menus | quantité à choisir, supplément par option |
| `customer` | clients facultatifs | |
| `payment_method` | moyens de paiement | `kind` CASH/CARD/CHECK/MEAL_VOUCHER/OTHER, `opens_drawer` |
| `document_sequence` | compteurs (tickets, attente) | verrou `FOR UPDATE` |
| `sale_order` | ventes / commandes en attente | `client_ref` unique (idempotence), `ticket_number` unique, statut HELD/PAID/CANCELLED/PARTIALLY_REFUNDED/REFUNDED, tous les totaux, `version` |
| `order_line` | lignes (et composants de menu via `parent_line_id`) | prix figés au moment de la vente |
| `order_line_modifier` | options figées | |
| `payment` | paiements | montant appliqué, `tendered`, `change_given` |
| `refund` | remboursements / annulations | motif, utilisateur, moyen |
| `cash_movement` | entrées / sorties | |
| `register_journal` | journal de caisse matérialisé | `event_type` |
| `daily_closure` | clôtures journalières | unique (`point_of_sale_id`, `business_date`), `details_json` |
| `receipt_template` | modèles de ticket | largeur 58/80, police, marges, en-tête, pied, `config_json` |
| `print_destination` | destinations (CLIENT, CUISINE, PIZZA, BOISSONS, PASSE…) | `kind`, `copies`, `show_prices` |
| `print_job` | travaux d'impression | contenu texte, statut PENDING/PRINTED/FAILED, `duplicate` |
| `audit_log` | audit | utilisateur, action, entité, détails |
| `app_setting` | paramètres clé/valeur | défauts dans `SettingsService` |

Relations principales : `company 1-n point_of_sale 1-n register 1-n register_session 1-n sale_order 1-n order_line 1-n order_line_modifier` ; `sale_order 1-n payment`, `sale_order 1-n refund`, `sale_order 1-n print_job`.
