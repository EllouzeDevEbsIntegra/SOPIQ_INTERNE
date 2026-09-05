-- Ingredients composant le nom des articles : « Omelette Thon Salami ».
--
-- Deux usages, et c'est le second qui commande la forme de ces tables.
--
--   1. Aider la saisie : on touche Omelette, Thon, Salami, et le nom s'ecrit.
--      Une simple concatenation aurait suffi pour cela.
--   2. Filtrer en caisse : « montre-moi les articles qui contiennent Omelette ET Thon ».
--      Cela exige de savoir QUELS ingredients composent un article, pas seulement de
--      lire son nom. D'ou le lien conserve en base, des maintenant : reconstituer plus
--      tard ce lien depuis des noms deja saisis serait impossible a coup sur - « Thon »
--      apparait dans « Thon » comme dans « Thonine ».
CREATE TABLE ingredient (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_ingredient_order ON ingredient(sort_order, id);
CREATE UNIQUE INDEX ux_ingredient_name ON ingredient(lower(name));

-- sort_order porte l'ordre des touches, qui est celui du nom : « Omelette Thon » et
-- « Thon Omelette » ne se lisent pas pareil sur un ticket.
--
-- La cle primaire (product_id, sort_order) est celle qu'attend JPA pour une liste
-- ordonnee ; l'unicite (product_id, ingredient_id) interdit en plus de poser deux fois
-- le meme ingredient sur un article, ce qui fausserait le filtre.
--
-- Supprimer un ingredient le retire des articles, mais leur NOM garde le mot : il a ete
-- copie dans une chaine de caracteres au moment de la saisie. Meme principe que les
-- remarques de cuisine - ce qui a ete imprime ne se reecrit pas.
CREATE TABLE product_ingredient (
    product_id BIGINT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    ingredient_id BIGINT NOT NULL REFERENCES ingredient(id) ON DELETE CASCADE,
    sort_order INT NOT NULL,
    PRIMARY KEY (product_id, sort_order),
    CONSTRAINT ux_product_ingredient UNIQUE (product_id, ingredient_id)
);
CREATE INDEX ix_product_ingredient_ing ON product_ingredient(ingredient_id);

-- Un point de depart tire de la carte d'un fast-food ; tout est modifiable ensuite.
INSERT INTO ingredient (name, sort_order) VALUES
    ('Omelette', 1), ('Thon', 2), ('Mozzarella', 3), ('Salami', 4), ('Kwika', 5),
    ('Escalope', 6), ('Viande hachée', 7), ('Fromage', 8), ('Harissa', 9), ('Salade', 10);
