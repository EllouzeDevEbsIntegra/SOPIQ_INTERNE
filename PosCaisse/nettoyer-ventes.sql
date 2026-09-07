-- =====================================================================
--  Remise a zero des VENTES, avant la mise en service chez le client.
--
--  Ce qui part : tout ce qui s'est passe. Tickets, lignes, paiements,
--  remboursements, mouvements de caisse, journal, sessions, clotures,
--  reglements de compte (donc les soldes clients), compteurs de tickets,
--  stock des pates et son historique, journal d'audit.
--
--  Ce qui reste : tout ce qui a ete PARAMETRE. Entreprise, points de vente,
--  caisses, utilisateurs et roles, categories, articles et menus, options,
--  ingredients, variantes et leurs prix, remarques cuisine, moyens de
--  paiement, imprimantes et modeles de ticket, clients et livreurs, et
--  l'integralite des reglages.
--
--  POURQUOI PAS L'ECRAN DE NETTOYAGE DU CATALOGUE. Celui-ci supprime aussi
--  les articles inactifs : c'est ce qu'on veut avant une refonte de carte,
--  pas avant une mise en service. Ici, la carte du client est deja juste -
--  on ne touche qu'a ce qu'elle a produit.
--
--  LES SOLDES CLIENTS ne sont pas une colonne : ils se deduisent des tickets
--  non regles moins les reglements. Effacer les deux les ramene donc a zero,
--  sans qu'aucun montant ne soit ecrit nulle part.
--
--  L'ordre des suppressions suit les cles etrangeres qui n'ont pas de
--  ON DELETE CASCADE (refund -> sale_order, account_payment -> session).
--  Le tout dans UNE transaction : en cas d'erreur, la base reste telle quelle.
-- =====================================================================

\set ON_ERROR_STOP on

\echo ''
\echo '== AVANT ============================================================'
SELECT 'tickets' AS quoi, count(*) FROM sale_order
UNION ALL SELECT 'lignes de vente', count(*) FROM order_line
UNION ALL SELECT 'paiements', count(*) FROM payment
UNION ALL SELECT 'remboursements', count(*) FROM refund
UNION ALL SELECT 'reglements clients', count(*) FROM account_payment
UNION ALL SELECT 'sessions de caisse', count(*) FROM register_session
UNION ALL SELECT 'lignes de journal', count(*) FROM register_journal
UNION ALL SELECT 'articles (garde)', count(*) FROM product
UNION ALL SELECT 'reglages (garde)', count(*) FROM app_setting;

BEGIN;

-- Ce qui pend a un ticket, avant le ticket lui-meme.
DELETE FROM print_job;
DELETE FROM refund;
DELETE FROM payment;
DELETE FROM order_line_modifier;
DELETE FROM order_line;

-- Les reglements de compte pointent la session de caisse : ils partent avant elle.
DELETE FROM account_payment;
DELETE FROM sale_order;

-- La caisse : mouvements, journal, clotures, sessions.
DELETE FROM cash_movement;
DELETE FROM register_journal;
DELETE FROM daily_closure;
DELETE FROM register_session;

-- Les compteurs de tickets : le premier ticket du client portera le numero 1.
DELETE FROM document_sequence;

-- Le stock des pates et son historique. Le parametrage des variantes, lui,
-- reste en place : ce sont les COMPTEURS qui repartent de zero, pas les regles.
DELETE FROM variant_stock_movement;
DELETE FROM variant_stock;

-- Le journal d'audit : il ne raconte que la periode d'essai.
DELETE FROM audit_log;

COMMIT;

\echo ''
\echo '== APRES ============================================================'
SELECT 'tickets' AS quoi, count(*) FROM sale_order
UNION ALL SELECT 'lignes de vente', count(*) FROM order_line
UNION ALL SELECT 'paiements', count(*) FROM payment
UNION ALL SELECT 'remboursements', count(*) FROM refund
UNION ALL SELECT 'reglements clients', count(*) FROM account_payment
UNION ALL SELECT 'sessions de caisse', count(*) FROM register_session
UNION ALL SELECT 'lignes de journal', count(*) FROM register_journal
UNION ALL SELECT 'stock des pates', count(*) FROM variant_stock;

\echo ''
\echo '== CE QUI EST CONSERVE =============================================='
SELECT 'categories' AS quoi, count(*) FROM category
UNION ALL SELECT 'articles et menus', count(*) FROM product
UNION ALL SELECT 'groupes d''options', count(*) FROM modifier_group
UNION ALL SELECT 'options', count(*) FROM modifier
UNION ALL SELECT 'ingredients', count(*) FROM ingredient
UNION ALL SELECT 'variantes', count(*) FROM variant
UNION ALL SELECT 'versions de variante', count(*) FROM variant_value
UNION ALL SELECT 'prix par version', count(*) FROM product_variant_price
UNION ALL SELECT 'remarques cuisine', count(*) FROM kitchen_note
UNION ALL SELECT 'moyens de paiement', count(*) FROM payment_method
UNION ALL SELECT 'imprimantes', count(*) FROM print_destination
UNION ALL SELECT 'modeles de ticket', count(*) FROM receipt_template
UNION ALL SELECT 'points de vente', count(*) FROM point_of_sale
UNION ALL SELECT 'caisses', count(*) FROM register
UNION ALL SELECT 'utilisateurs', count(*) FROM app_user
UNION ALL SELECT 'clients', count(*) FROM customer
UNION ALL SELECT 'livreurs', count(*) FROM courier
UNION ALL SELECT 'reglages', count(*) FROM app_setting;
\echo ''
