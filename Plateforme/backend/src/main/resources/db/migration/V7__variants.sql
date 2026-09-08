-- Variantes d'article : Petite / Moyenne / Large, Normale / Cereales / Chia,
-- Demi-baguette / Baguette entiere.
--
-- Une variante n'est PAS une option. Le client ne commande pas « une pizza thon avec du
-- large » : il commande « une pizza thon large ». C'est le produit qui change, pas un
-- ajout. D'ou trois differences avec les groupes d'options existants, qui restent en
-- place et servent toujours aux vrais supplements :
--
--   1. le prix est COMPLET, pas un supplement - « Large = 18 DT », et non « + 3 DT ».
--      Aucune arithmetique cachee, aucune hypothese sur la decomposabilite des tarifs ;
--   2. la valeur choisie entre DANS LE NOM sur le ticket, en prefixe ou en suffixe :
--      « 1/2 Sandwich Omelette Thon » d'un cote, « Pizza Thon Large » de l'autre ;
--   3. un article porte AU PLUS UNE variante. C'est la contrainte qui evite la
--      combinatoire : trois pates fois deux fromages fois trois tailles donnerait dix-huit
--      combinaisons a saisir, une grille tactile illisible et des prix qui divergent.
--      Quand deux caracteristiques varient, la seconde se traite en articles distincts.

CREATE TABLE variant (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL,
    -- SUFFIX : « Pizza Thon Large ». PREFIX : « 1/2 Sandwich Omelette Thon ».
    name_position VARCHAR(10) NOT NULL DEFAULT 'SUFFIX',
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_variant_position CHECK (name_position IN ('PREFIX', 'SUFFIX'))
);
CREATE UNIQUE INDEX ux_variant_name ON variant(lower(name));

-- short_name sert le ticket : le papier fait 42 caracteres, et « Large » y coute cinq de
-- plus que « L » sur chaque ligne. Vide, c'est le nom complet qui s'imprime.
CREATE TABLE variant_value (
    id BIGSERIAL PRIMARY KEY,
    variant_id BIGINT NOT NULL REFERENCES variant(id) ON DELETE CASCADE,
    name VARCHAR(60) NOT NULL,
    short_name VARCHAR(20),
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX ix_variant_value_ordre ON variant_value(variant_id, sort_order, id);

ALTER TABLE product ADD COLUMN variant_id BIGINT REFERENCES variant(id);
-- La valeur par defaut est ce que vend un appui court. Elle doit exister et porter un
-- prix : sans elle, la tuile ne saurait meme pas quel prix afficher.
ALTER TABLE product ADD COLUMN default_variant_value_id BIGINT REFERENCES variant_value(id);
-- Reglage par article, et non par carte : sur un mlewi ou neuf pates sur dix sont
-- normales, un appui suffit ; sur une pizza ou les trois tailles se valent, mieux vaut
-- toujours demander que de vendre une moyenne par reflexe.
ALTER TABLE product ADD COLUMN ask_variant BOOLEAN NOT NULL DEFAULT false;

-- Le prix se tient par article ET par valeur : la meme « Large » ne vaut pas le meme
-- prix sur une pizza thon et sur une pizza fruits de mer.
--
-- Une valeur sans ligne ici, ou a prix nul, n'est pas proposee en caisse : c'est le cas
-- d'une valeur ajoutee a la variante APRES le parametrage de l'article. Elle reste
-- visible, grisee, pour que le gerant voie ce qui lui reste a faire.
CREATE TABLE product_variant_price (
    product_id BIGINT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    variant_value_id BIGINT NOT NULL REFERENCES variant_value(id) ON DELETE CASCADE,
    price NUMERIC(14,3) NOT NULL DEFAULT 0,
    PRIMARY KEY (product_id, variant_value_id)
);
CREATE INDEX ix_pvp_valeur ON product_variant_price(variant_value_id);

-- La ligne vendue garde une COPIE du nom et du prix : renommer « Large » en « XL » l'an
-- prochain ne doit pas reecrire les tickets de cette annee. Meme principe que les
-- remarques de cuisine et les noms d'articles deja copies ici.
ALTER TABLE order_line ADD COLUMN variant_value_id BIGINT REFERENCES variant_value(id);
ALTER TABLE order_line ADD COLUMN variant_value_name VARCHAR(60);
ALTER TABLE order_line ADD COLUMN variant_value_short_name VARCHAR(20);
CREATE INDEX ix_order_line_variante ON order_line(variant_value_id);

-- Un point de depart tire de la carte observee ; tout est modifiable ensuite.
INSERT INTO variant (name, name_position, sort_order) VALUES
    ('Taille', 'SUFFIX', 1), ('Pâte', 'SUFFIX', 2), ('Format', 'PREFIX', 3);

INSERT INTO variant_value (variant_id, name, short_name, sort_order)
SELECT v.id, x.nom, x.court, x.rang FROM variant v
JOIN (VALUES ('Taille', 'Petite', 'P', 1), ('Taille', 'Moyenne', 'M', 2), ('Taille', 'Large', 'L', 3),
             ('Pâte', 'Normale', NULL, 1), ('Pâte', 'Céréales', 'Cér.', 2), ('Pâte', 'Chia', NULL, 3),
             ('Format', '1/2', NULL, 1), ('Format', 'Entier', NULL, 2)
     ) AS x(variante, nom, court, rang) ON x.variante = v.name;
