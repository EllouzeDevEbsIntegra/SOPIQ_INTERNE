-- =====================================================================
--  Mettre a jour le prix d'une liste d'articles, sur toutes les pates.
--
--  LE CAS. Le patron donne une liste de prix : un prix par article, celui
--  de la pate NORMALE. Les autres pates s'en deduisent - Chapati au meme
--  prix, Cereale +1,000, Chia +1,500. Reprendre trente fiches article a la
--  main, c'est une heure de saisie et une occasion de se tromper quelque
--  part ; et une erreur sur un prix ne se voit pas avant la caisse.
--
--  CE QUE FAIT CE SCRIPT. Pour les articles NOMMES plus bas, et pour eux
--  seuls, il ECRASE le prix de chaque pate. Ce n'est pas << copier-prix-version >>,
--  qui ne remplit que les cases vides : ici, c'est une grille tarifaire qui
--  remplace l'ancienne, y compris un prix saisi a la main.
--
--  LES PATES DOUBLES SUIVENT, sur la meme regle que catalogs\prix-double-pate.ps1 :
--  Double = la pate simple + un supplement (Normale +1,000, Chapati +1,000,
--  Cereale +1,000, Chia +1,500). C'est la meme pate au frigo, comptee deux
--  fois : son prix doit suivre celui de la simple, sinon la double reste au
--  tarif d'avant et la difference se paie a la caisse.
--
--  CE QU'IL NE TOUCHE PAS. Les articles absents de la liste. Et le prix de
--  base de la fiche article (colonne << price >>), qui ne sert pas a la vente
--  d'un article decline : il est seulement rapporte a la fin, pour information.
--
--  RIEN N'EST DEVINE. Si l'un des quatre noms de pate SIMPLE regles ci-dessous
--  n'existe pas dans la carte, le script s'arrete AVANT d'ecrire et affiche
--  les noms disponibles : mieux vaut ne rien faire que tarifer a cote. Une
--  DOUBLE absente, elle, est simplement ignoree et nommee a la fin - toutes
--  les cartes n'ont pas les quatre.
--
--  A REGLER : les huit noms de version et les supplements. Les noms sont ceux
--  du back-office ; la casse, les accents et les espaces en trop n'ont pas
--  d'importance.
-- =====================================================================

\set ON_ERROR_STOP on

-- Les pates simples. Obligatoires : une seule absente et le script s'arrete.
\set v_normale 'Pate Normale'
\set v_chapati 'Chapati'
\set v_cereale 'Pate Cereale'
\set v_chia    'Pate Chia'

-- Les pates doubles. Facultatives : celles qui n'existent pas sont ignorees.
-- Chez NUMBER ONE elles se nomment << Double Pate ... >>, et il n'y a pas de
-- double pour Chapati : la ligne reste, elle sera simplement ignoree.
\set v_d_normale 'Double Pate Normale'
\set v_d_chapati 'Double Pate Chapati'
\set v_d_cereale 'Double Pate Cereale'
\set v_d_chia    'Double Pate Chia'

-- Ce que chaque pate ajoute au prix de la liste.
\set sup_chapati 0.000
\set sup_cereale 1.000
\set sup_chia    1.500

-- Ce qu'une DOUBLE ajoute au prix de sa simple.
\set dbl_normale 1.000
\set dbl_chapati 1.000
\set dbl_cereale 1.000
\set dbl_chia    1.500

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
--  Les versions, et ce que chacune ajoute au prix de la liste.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS version;
CREATE TEMP TABLE version (rang int, pate text, nom_voulu text, supplement numeric(14,3),
                           obligatoire boolean, id bigint, nom text) ON COMMIT PRESERVE ROWS;
/*
    Le supplement d'une double est ecrit tel qu'il se raisonne : celui de sa
    pate simple, plus ce que la double ajoute. Le total ne se lit pas sur une
    etiquette de prix, mais la regle, elle, se relit et se corrige.
*/
INSERT INTO version (rang, pate, nom_voulu, supplement, obligatoire) VALUES
  (1, 'Normale',        :'v_normale',   0.000,                      true),
  (2, 'Chapati',        :'v_chapati',   :sup_chapati,               true),
  (3, 'Céréale',        :'v_cereale',   :sup_cereale,               true),
  (4, 'Chia',           :'v_chia',      :sup_chia,                  true),
  (5, 'Double Normale', :'v_d_normale', 0.000 + :dbl_normale,       false),
  (6, 'Double Chapati', :'v_d_chapati', :sup_chapati + :dbl_chapati, false),
  (7, 'Double Céréale', :'v_d_cereale', :sup_cereale + :dbl_cereale, false),
  (8, 'Double Chia',    :'v_d_chia',    :sup_chia + :dbl_chia,      false);

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
SELECT nom_voulu AS "nom reglé", coalesce(nom, '— absente de la carte —') AS "trouvé dans la carte",
       supplement AS "supplément", CASE WHEN obligatoire THEN 'oui' ELSE 'facultative' END AS "obligatoire"
FROM version ORDER BY rang;

/*
    L'arret net. Une version manquante, et c'est toute une colonne de prix
    qui resterait a 0 sans que rien ne le dise : la caisse griserait la pate
    et personne ne comprendrait pourquoi. On s'arrete, en nommant ce qui
    existe reellement.
*/
DO $$
DECLARE manquants text; dispo text;
BEGIN
  SELECT string_agg('« ' || nom_voulu || ' »', ', ') INTO manquants FROM version WHERE id IS NULL AND obligatoire;
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
WHERE p.variant_id = (SELECT variant_id FROM variant_value WHERE id = (SELECT id FROM version WHERE rang = 1));

\echo ''
\echo '== CE QUI VA CHANGER ================================================'
SELECT c.article,
       v.nom AS version,
       coalesce(pvp.price, 0) AS "prix actuel",
       c.prix + v.supplement AS "nouveau prix"
FROM cible c
CROSS JOIN version v
LEFT JOIN product_variant_price pvp ON pvp.product_id = c.product_id AND pvp.variant_value_id = v.id
WHERE v.id IS NOT NULL AND coalesce(pvp.price, -1) <> c.prix + v.supplement
ORDER BY c.article, v.rang;

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
WHERE v.id IS NOT NULL
ON CONFLICT (product_id, variant_value_id) DO UPDATE SET price = EXCLUDED.price;

COMMIT;

\echo ''
\echo '== APRES, LES PATES SIMPLES ========================================='
SELECT c.article,
       max(CASE WHEN v.rang = 1 THEN pvp.price END) AS normale,
       max(CASE WHEN v.rang = 2 THEN pvp.price END) AS chapati,
       max(CASE WHEN v.rang = 3 THEN pvp.price END) AS "céréale",
       max(CASE WHEN v.rang = 4 THEN pvp.price END) AS chia
FROM cible c
JOIN version v ON v.rang <= 4
JOIN product_variant_price pvp ON pvp.product_id = c.product_id AND pvp.variant_value_id = v.id
GROUP BY c.article
ORDER BY c.article;

\echo ''
\echo '== APRES, LES PATES DOUBLES ========================================='
SELECT c.article,
       max(CASE WHEN v.rang = 5 THEN pvp.price END) AS "double normale",
       max(CASE WHEN v.rang = 6 THEN pvp.price END) AS "double chapati",
       max(CASE WHEN v.rang = 7 THEN pvp.price END) AS "double céréale",
       max(CASE WHEN v.rang = 8 THEN pvp.price END) AS "double chia"
FROM cible c
JOIN version v ON v.rang > 4
JOIN product_variant_price pvp ON pvp.product_id = c.product_id AND pvp.variant_value_id = v.id
GROUP BY c.article
ORDER BY c.article;

\echo ''
\echo '== LES VERSIONS NON TRAITEES (a regarder) ==========================='
-- D'un cote les doubles reglees en haut mais absentes de la carte : leur nom
-- est peut-etre ecrit autrement ici. De l'autre, les versions de l'axe que la
-- liste ne mentionne pas : elles gardent le prix qu'elles avaient.
SELECT nom_voulu AS version, 'reglée dans le script, absente de la carte' AS quoi
FROM version WHERE id IS NULL
UNION ALL
SELECT DISTINCT x.name, 'présente dans la carte, hors du script — prix inchangé'
FROM cible c
JOIN product_variant_price pvp ON pvp.product_id = c.product_id
JOIN variant_value x ON x.id = pvp.variant_value_id
WHERE x.id NOT IN (SELECT id FROM version WHERE id IS NOT NULL)
ORDER BY 2, 1;

\echo ''
\echo '== PRIX DE BASE DE LA FICHE, NON TOUCHE (pour information) =========='
-- Il ne sert pas a la vente d'un article decline - c'est la version choisie
-- qui porte le prix - mais un ecart franc signale souvent une fiche a revoir.
SELECT c.article, p.price AS "prix de base", c.prix AS "prix normale"
FROM cible c JOIN product p ON p.id = c.product_id
WHERE p.price <> c.prix
ORDER BY c.article;
\echo ''
