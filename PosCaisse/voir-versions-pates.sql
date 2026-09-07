-- =====================================================================
--  REGARDER, SANS RIEN ECRIRE : les versions de pate de cette carte.
--
--  A lancer AVANT mettre-a-jour-prix-pates.sql. Ce dernier a besoin des
--  noms EXACTS des versions ; ils different d'une installation a l'autre
--  (<< Normale >> ici, << Pate Normale >> ailleurs), et une double peut ne pas
--  exister du tout. Ce fichier les affiche, et rien d'autre : aucune ligne
--  n'est modifiee, il peut se relancer autant de fois qu'on veut.
--
--  Recopiez les noms de la premiere colonne dans les lignes \set en haut de
--  mettre-a-jour-prix-pates.sql.
-- =====================================================================

\echo ''
\echo '== LES AXES DE VARIANTE ============================================='
SELECT v.id, v.name AS axe, v.active AS activé, count(p.id) AS "articles qui le portent"
FROM variant v LEFT JOIN product p ON p.variant_id = v.id
GROUP BY v.id, v.name, v.active ORDER BY v.sort_order, v.id;

\echo ''
\echo '== LES VERSIONS, AVEC CE QUI EST DEJA TARIFE ========================'
-- << articles tarifes >> compte les fiches ou cette version porte un prix > 0.
-- Une version a 0 partout est grisee en caisse : elle n'est pas vendable.
SELECT a.name AS axe, x.id, x.name AS version, x.active AS activée,
       CASE WHEN x.stock_managed THEN 'compteur propre'
            WHEN x.stock_source_id IS NOT NULL THEN 'tire sur ' || s.name || ' ×' || trim(trailing '.' from trim(trailing '0' from x.stock_step::text))
            ELSE '—' END AS stock,
       count(*) FILTER (WHERE pvp.price > 0) AS "articles tarifés",
       min(pvp.price) FILTER (WHERE pvp.price > 0) AS "prix mini",
       max(pvp.price) FILTER (WHERE pvp.price > 0) AS "prix maxi"
FROM variant_value x
JOIN variant a ON a.id = x.variant_id
LEFT JOIN variant_value s ON s.id = x.stock_source_id
LEFT JOIN product_variant_price pvp ON pvp.variant_value_id = x.id
GROUP BY a.sort_order, a.name, x.id, x.name, x.active, x.stock_managed, x.stock_source_id, x.stock_step, s.name, x.sort_order
ORDER BY a.sort_order, x.sort_order, x.id;
\echo ''
