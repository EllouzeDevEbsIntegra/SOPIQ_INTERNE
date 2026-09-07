-- =====================================================================
--  Recopier le prix d'une version de variante sur une autre.
--
--  Le cas : une version est ajoutee a un axe deja tarife - << Chapati >> vient
--  s'ajouter aux pates - et elle arrive a 0 sur les dizaines d'articles qui
--  portent cet axe. A 0, la caisse la montre grisee : elle n'est pas vendable.
--  Les reprendre une par une dans les fiches article, c'est une heure de saisie
--  et une occasion de se tromper quelque part.
--
--  CE QUE FAIT CE SCRIPT. Pour chaque article portant l'axe, il donne a la
--  version CIBLE le prix que l'article donne deja a la version SOURCE.
--
--  CE QU'IL NE FAIT PAS. Il n'ecrase aucun prix deja saisi : seules les cases
--  vides ou a 0 sont remplies. Relance-le deux fois de suite ne change donc
--  rien la seconde fois, et un prix corrige a la main lui survit.
--
--  A REGLER, les deux lignes ci-dessous : la version qui DONNE son prix, et
--  celle qui le RECOIT. Les noms sont ceux du back-office, la casse et les
--  accents n'ont pas d'importance.
-- =====================================================================

\set ON_ERROR_STOP on

\set source 'Pate Normale'
\set cible  'Chapati'

\echo ''
\echo '== CE QUI VA CHANGER ================================================='
SELECT p.name AS article,
       src.price AS prix_source,
       coalesce(dst.price, 0) AS prix_cible_actuel
FROM variant_value cible
JOIN variant_value source ON source.variant_id = cible.variant_id
                         AND lower(btrim(source.name)) = lower(btrim(:'source'))
JOIN product_variant_price src ON src.variant_value_id = source.id
JOIN product p ON p.id = src.product_id AND p.variant_id = cible.variant_id
LEFT JOIN product_variant_price dst ON dst.product_id = src.product_id
                                   AND dst.variant_value_id = cible.id
WHERE lower(btrim(cible.name)) = lower(btrim(:'cible'))
  AND src.price > 0
  AND (dst.product_id IS NULL OR dst.price = 0)
ORDER BY p.name;

BEGIN;

/*
    L'ecriture. La cle primaire porte sur (article, version) : ON CONFLICT met
    donc a jour la ligne existante quand la case etait a 0, et en cree une
    quand elle n'existait pas du tout - les deux cas se presentent, selon que
    la fiche a ete ouverte depuis l'ajout de la version ou non.

    Les deux versions doivent appartenir au MEME axe, et l'article le porter :
    sans cela on tariferait une pate sur un article qui se decline en tailles.
*/
INSERT INTO product_variant_price (product_id, variant_value_id, price)
SELECT src.product_id, cible.id, src.price
FROM variant_value cible
JOIN variant_value source ON source.variant_id = cible.variant_id
                         AND lower(btrim(source.name)) = lower(btrim(:'source'))
JOIN product_variant_price src ON src.variant_value_id = source.id
JOIN product p ON p.id = src.product_id AND p.variant_id = cible.variant_id
LEFT JOIN product_variant_price dst ON dst.product_id = src.product_id
                                   AND dst.variant_value_id = cible.id
WHERE lower(btrim(cible.name)) = lower(btrim(:'cible'))
  AND src.price > 0
  AND (dst.product_id IS NULL OR dst.price = 0)
ON CONFLICT (product_id, variant_value_id) DO UPDATE SET price = EXCLUDED.price;

COMMIT;

\echo ''
\echo '== APRES ============================================================='
SELECT p.name AS article,
       src.price AS prix_source,
       dst.price AS prix_cible
FROM variant_value cible
JOIN variant_value source ON source.variant_id = cible.variant_id
                         AND lower(btrim(source.name)) = lower(btrim(:'source'))
JOIN product_variant_price src ON src.variant_value_id = source.id
JOIN product p ON p.id = src.product_id AND p.variant_id = cible.variant_id
JOIN product_variant_price dst ON dst.product_id = src.product_id
                              AND dst.variant_value_id = cible.id
WHERE lower(btrim(cible.name)) = lower(btrim(:'cible'))
ORDER BY p.name;

\echo ''
\echo '== CE QUI RESTE A 0 (a regarder) ====================================='
-- Un article dont la source elle-meme n'est pas tarifee ne peut rien recevoir :
-- il apparait ici plutot que de passer inapercu.
SELECT p.name AS article, coalesce(src.price, 0) AS prix_source, coalesce(dst.price, 0) AS prix_cible
FROM product p
JOIN variant_value cible ON cible.variant_id = p.variant_id
                        AND lower(btrim(cible.name)) = lower(btrim(:'cible'))
LEFT JOIN variant_value source ON source.variant_id = p.variant_id
                              AND lower(btrim(source.name)) = lower(btrim(:'source'))
LEFT JOIN product_variant_price src ON src.product_id = p.id AND src.variant_value_id = source.id
LEFT JOIN product_variant_price dst ON dst.product_id = p.id AND dst.variant_value_id = cible.id
WHERE coalesce(dst.price, 0) = 0
ORDER BY p.name;
\echo ''
