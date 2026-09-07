-- =====================================================================
--  Mettre a jour le prix d'une liste d'articles, sur les quatre pates.
--
--  LE CAS. Le patron donne une liste de prix : un prix par article, celui
--  de la pate NORMALE. Les autres pates s'en deduisent - Chapati au meme
--  prix, Cereale +1,000, Chia +1,500. Reprendre trente fiches article a la
--  main, c'est une heure de saisie et une occasion de se tromper quelque
--  part ; et une erreur sur un prix ne se voit pas avant la caisse.
--
--  CE QUE FAIT CE SCRIPT. Pour les articles NOMMES plus bas, et pour eux
--  seuls, il ECRASE les quatre prix. Ce n'est pas << copier-prix-version >>,
--  qui ne remplit que les cases vides : ici, c'est une grille tarifaire qui
--  remplace l'ancienne, y compris un prix saisi a la main.
--
--  CE QU'IL NE TOUCHE PAS. Les articles absents de la liste. Les pates
--  DOUBLES - elles se recalculent ensuite avec catalogs\prix-double-pate.ps1,
--  qui pose Double = simple + supplement. Et le prix de base de la fiche
--  article (colonne << price >>), qui ne sert pas a la vente d'un article
--  decline : il est seulement rapporte a la fin, pour information.
--
--  RIEN N'EST DEVINE. Si l'un des quatre noms de version regles ci-dessous
--  n'existe pas dans la carte, le script s'arrete AVANT d'ecrire et affiche
--  les noms disponibles : mieux vaut ne rien faire que tarifer a cote.
--
--  A REGLER : les quatre noms de version et les deux supplements. Les noms
--  sont ceux du back-office ; la casse, les accents et les espaces en trop
--  n'ont pas d'importance.
-- =====================================================================

\set ON_ERROR_STOP on

\set v_normale 'Pate Normale'
\set v_chapati 'Chapati'
\set v_cereale 'Pate Cereale'
\set v_chia    'Pate Chia'

\set sup_chapati 0.000
\set sup_cereale 1.000
\set sup_chia    1.500

-- ---------------------------------------------------------------------
--  La cle de rapprochement : ce qui reste d'un nom quand on enleve ce qui
--  varie d'une saisie a l'autre - accents, majuscules, espaces doubles,
--  tirets. << Escalope Grillé >> et << escalope grille >> deviennent la meme
--  chose, et un nom mal accentue ne fait plus rater un article.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.cle(t text) RETURNS text AS $$
  SELECT btrim(regexp_replace(
           lower(translate(coalesce($1, ''),
             'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÝýÿÇçÑñ',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuYyyCcNn')),
           '[^a-z0-9]+', ' ', 'g'))
$$ LANGUAGE sql IMMUTABLE;

-- ---------------------------------------------------------------------
--  LA LISTE. Un article, et son prix en pate NORMALE.
--  Les noms sont ceux de la carte : << omlette jambon >> de la liste papier
--  s'appelle << Omlette Jombon >> dans le back-office, et c'est cette
--  orthographe-la qui compte.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS tarif;
CREATE TEMP TABLE tarif (nom text, prix numeric(14,3)) ON COMMIT PRESERVE ROWS;
INSERT INTO tarif (nom, prix) VALUES
  -- Omlette + garniture
  ('Omlette Thon',                        5.500),
  ('Omlette Jombon',                      5.500),
  ('Omlette Kabeb',                       6.700),
  ('Omlette Chawarma',                    6.700),
  ('Omlette Escalope Grillé',             6.700),
  ('Omlette Escalope Pané',                7.700),
  ('Omlette Cordon Bleu',                 7.700),
  -- Omlette Fromage + garniture
  ('Omlette Fromage Kwika',               4.500),
  ('Omlette Fromage Salami',              5.000),
  ('Omlette Fromage Thon',                6.000),
  ('Omlette Fromage Jombon',              6.000),
  ('Omlette Fromage Kabeb',               7.400),
  ('Omlette Fromage Chawarma',            7.400),
  ('Omlette Fromage Escalope Grillé',     7.400),
  ('Omlette Fromage Escalope Pané',       8.400),
  ('Omlette Fromage Cordon Bleu',         8.400),
  -- Avec Mozarilla
  ('Kwika Mozarilla',                     5.000),
  ('Salami Mozarilla',                    5.500),
  ('Kabeb Mozarilla',                     8.000),
  ('Chawarma Mozarilla',                  8.000),
  ('Escalope Grillé Mozarilla',           8.000),
  ('Escalope Pané Mozarilla',             9.000),
  ('Cordon Bleu Mozarilla',               9.000),
  -- Avec Mozarilla 3arbi
  ('Kwika Mozarilla 3arbi',               6.000),
  ('Salami Mozarilla 3arbi',              6.500),
  ('Kabeb Mozarilla 3arbi',               9.000),
  ('Chawarma Mozarilla 3arbi',            9.000),
  ('Escalope Grillé Mozarilla 3arbi',     9.000),
  ('Escalope Pané Mozarilla 3arbi',      10.000),
  ('Cordon Bleu Mozarilla 3arbi',        10.000);

-- ---------------------------------------------------------------------
--  Les quatre versions, et ce qu'elles ajoutent au prix de la liste.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS version;
CREATE TEMP TABLE version (role text, nom_voulu text, supplement numeric(14,3), id bigint, nom text)
  ON COMMIT PRESERVE ROWS;
INSERT INTO version (role, nom_voulu, supplement) VALUES
  ('normale', :'v_normale', 0.000),
  ('chapati', :'v_chapati', :sup_chapati),
  ('cereale', :'v_cereale', :sup_cereale),
  ('chia',    :'v_chia',    :sup_chia);

UPDATE version v SET id = x.id, nom = x.name
FROM variant_value x
WHERE pg_temp.cle(x.name) = pg_temp.cle(v.nom_voulu);

\echo ''
\echo '== LES VERSIONS DE L''AXE, TELLES QUE LA CARTE LES NOMME ============='
SELECT a.name AS axe, x.id, x.name AS version, x.active AS activee
FROM variant_value x JOIN variant a ON a.id = x.variant_id
WHERE a.id IN (SELECT variant_id FROM variant_value WHERE id IN (SELECT id FROM version WHERE id IS NOT NULL))
ORDER BY x.sort_order, x.id;

\echo ''
\echo '== CE QUE LE SCRIPT VA APPLIQUER ===================================='
SELECT role AS r, nom_voulu AS "nom reglé", nom AS "trouvé dans la carte", supplement AS "supplément"
FROM version ORDER BY CASE role WHEN 'normale' THEN 1 WHEN 'chapati' THEN 2 WHEN 'cereale' THEN 3 ELSE 4 END;

/*
    L'arret net. Une version manquante, et c'est toute une colonne de prix
    qui resterait a 0 sans que rien ne le dise : la caisse griserait la pate
    et personne ne comprendrait pourquoi. On s'arrete, en nommant ce qui
    existe reellement.
*/
DO $$
DECLARE manquants text; dispo text;
BEGIN
  SELECT string_agg('« ' || nom_voulu || ' »', ', ') INTO manquants FROM version WHERE id IS NULL;
  IF manquants IS NOT NULL THEN
    SELECT string_agg('« ' || x.name || ' »', ', ' ORDER BY x.name) INTO dispo
    FROM variant_value x JOIN variant a ON a.id = x.variant_id;
    RAISE EXCEPTION E'Version introuvable : %.\nRien n''a ete modifie.\nVersions existantes : %.\nCorrigez les lignes \\set en haut du script.', manquants, dispo;
  END IF;
END $$;

-- Les articles vises : ceux de la liste qui portent bien l'axe des pates.
DROP TABLE IF EXISTS cible;
CREATE TEMP TABLE cible ON COMMIT PRESERVE ROWS AS
SELECT p.id AS product_id, p.name AS article, t.prix
FROM tarif t
JOIN product p ON pg_temp.cle(p.name) = pg_temp.cle(t.nom)
WHERE p.variant_id = (SELECT variant_id FROM variant_value WHERE id = (SELECT id FROM version WHERE role = 'normale'));

\echo ''
\echo '== CE QUI VA CHANGER ================================================'
SELECT c.article,
       v.nom AS version,
       coalesce(pvp.price, 0) AS "prix actuel",
       c.prix + v.supplement AS "nouveau prix"
FROM cible c
CROSS JOIN version v
LEFT JOIN product_variant_price pvp ON pvp.product_id = c.product_id AND pvp.variant_value_id = v.id
WHERE coalesce(pvp.price, -1) <> c.prix + v.supplement
ORDER BY c.article, CASE v.role WHEN 'normale' THEN 1 WHEN 'chapati' THEN 2 WHEN 'cereale' THEN 3 ELSE 4 END;

\echo ''
\echo '== CE QUI N''A PAS ETE TROUVE (a regarder) =========================='
-- Un nom de la liste qui ne tombe sur aucun article, ou sur un article qui
-- ne se decline pas en pates : il apparait ici plutot que de passer inapercu.
SELECT t.nom AS "nom de la liste", t.prix,
       CASE WHEN p.id IS NULL THEN 'aucun article de ce nom'
            ELSE 'article trouve, mais il ne porte pas la variante Pâte' END AS pourquoi
FROM tarif t
LEFT JOIN product p ON pg_temp.cle(p.name) = pg_temp.cle(t.nom)
WHERE NOT EXISTS (SELECT 1 FROM cible c WHERE pg_temp.cle(c.article) = pg_temp.cle(t.nom))
ORDER BY t.nom;

\echo ''
\echo '== NOMS PORTES PAR PLUSIEURS ARTICLES (a regarder) =================='
-- Deux fiches du meme nom recevraient toutes deux le prix de la liste. C'est
-- peut-etre voulu (la meme garniture dans deux rubriques), peut-etre un doublon
-- oublie : dans les deux cas, mieux vaut le savoir avant de vendre.
SELECT article, count(*) AS fiches
FROM cible GROUP BY article HAVING count(*) > 1 ORDER BY article;

BEGIN;

/*
    L'ecriture. La cle primaire porte sur (article, version) : ON CONFLICT
    met a jour la ligne quand elle existe, et la cree quand la fiche n'a
    jamais ete ouverte depuis l'ajout de la version - les deux cas se
    presentent sur la meme carte.
*/
INSERT INTO product_variant_price (product_id, variant_value_id, price)
SELECT c.product_id, v.id, c.prix + v.supplement
FROM cible c CROSS JOIN version v
ON CONFLICT (product_id, variant_value_id) DO UPDATE SET price = EXCLUDED.price;

COMMIT;

\echo ''
\echo '== APRES ============================================================'
SELECT c.article,
       max(CASE WHEN v.role = 'normale' THEN pvp.price END) AS normale,
       max(CASE WHEN v.role = 'chapati' THEN pvp.price END) AS chapati,
       max(CASE WHEN v.role = 'cereale' THEN pvp.price END) AS "céréale",
       max(CASE WHEN v.role = 'chia'    THEN pvp.price END) AS chia
FROM cible c
CROSS JOIN version v
JOIN product_variant_price pvp ON pvp.product_id = c.product_id AND pvp.variant_value_id = v.id
GROUP BY c.article
ORDER BY c.article;

\echo ''
\echo '== LES PATES DOUBLES, NON TOUCHEES (pour memoire) ==================='
-- Elles se recalculent ensuite : catalogs\prix-double-pate.ps1 pose
-- Double = simple + supplement, sur toute la carte d'un coup.
SELECT x.name AS version, count(*) AS "articles de la liste", min(pvp.price) AS "prix mini", max(pvp.price) AS "prix maxi"
FROM cible c
JOIN product_variant_price pvp ON pvp.product_id = c.product_id
JOIN variant_value x ON x.id = pvp.variant_value_id
WHERE x.id NOT IN (SELECT id FROM version)
GROUP BY x.name ORDER BY x.name;

\echo ''
\echo '== PRIX DE BASE DE LA FICHE, NON TOUCHE (pour information) =========='
-- Il ne sert pas a la vente d'un article decline - c'est la version choisie
-- qui porte le prix - mais un ecart franc signale souvent une fiche a revoir.
SELECT c.article, p.price AS "prix de base", c.prix AS "prix normale"
FROM cible c JOIN product p ON p.id = c.product_id
WHERE p.price <> c.prix
ORDER BY c.article;
\echo ''
