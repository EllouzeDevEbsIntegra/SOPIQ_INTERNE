-- Stock par valeur de variante : les pates du jour.
--
-- Ce n'est pas un stock d'articles. Ce qui s'epuise chez NUMBER ONE, ce n'est pas
-- « Omlette Thon » : c'est la PATE. Une meme pate normale sert quarante sandwichs
-- differents, et c'est elle qui manque a 21 h. Le compteur se pose donc sur la valeur
-- de variante, la ou la penurie se produit reellement.
--
-- TROIS DECISIONS, prises avec le restaurateur :
--
--   1. Le stock appartient au POINT DE VENTE, pas a la caisse. La pate est dans le
--      frigo du restaurant ; deux caisses qui vendent le meme stock physique doivent
--      voir le meme compteur, sinon chacune se croit seule et on vend deux fois la
--      derniere pate.
--   2. Il repart a ZERO a la cloture journaliere. La pate ne se garde pas d'un jour a
--      l'autre : un report ferait croire au matin a un stock qui n'existe plus.
--   3. Une valeur peut ne pas porter de stock et TIRER SUR UNE AUTRE. « Double
--      Normale » n'a pas son propre stock : elle consomme deux pates normales. C'est
--      la meme pate au frigo, comptee deux fois - une seule verite, un seul compteur.

ALTER TABLE variant_value
    -- Suivie ou non. Faux partout au depart : rien ne change tant que le gerant n'a pas
    -- dit lui-meme quelles valeurs se comptent.
    ADD COLUMN stock_managed BOOLEAN NOT NULL DEFAULT false,
    -- Ce qu'une vente retire du compteur. 1 pour une pate normale, 2 pour une double,
    -- et le pas existe aussi pour ce qui se vend par lot (10 pains d'un paquet).
    ADD COLUMN stock_step NUMERIC(10,3) NOT NULL DEFAULT 1,
    -- La valeur sur laquelle celle-ci tire, quand elle n'a pas de stock propre.
    ADD COLUMN stock_source_id BIGINT REFERENCES variant_value(id);

-- Une valeur ne peut pas etre a la fois un compteur et un emprunteur : sinon la meme
-- vente retirerait deux fois, ici et chez la source.
ALTER TABLE variant_value
    ADD CONSTRAINT ck_variant_value_stock CHECK (NOT (stock_managed AND stock_source_id IS NOT NULL)),
    ADD CONSTRAINT ck_variant_value_stock_pas CHECK (stock_step > 0),
    -- Une valeur ne tire pas sur elle-meme.
    ADD CONSTRAINT ck_variant_value_stock_source CHECK (stock_source_id IS NULL OR stock_source_id <> id);

-- Le compteur : une ligne par point de vente et par valeur suivie.
CREATE TABLE variant_stock (
    id BIGSERIAL PRIMARY KEY,
    point_of_sale_id BIGINT NOT NULL REFERENCES point_of_sale(id),
    variant_value_id BIGINT NOT NULL REFERENCES variant_value(id),
    quantity NUMERIC(12,3) NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Un seul compteur par pate et par point de vente : c'est cette unicite qui permet de
-- verrouiller la ligne pendant une vente et d'empecher deux caisses de vendre en meme
-- temps la derniere pate.
CREATE UNIQUE INDEX ux_variant_stock ON variant_stock(point_of_sale_id, variant_value_id);

-- Le detail des mouvements. Sans lui, un stock qui ne tombe pas juste le soir ne
-- s'explique pas : on voit un chiffre, jamais ce qui l'a fait bouger.
CREATE TABLE variant_stock_movement (
    id BIGSERIAL PRIMARY KEY,
    point_of_sale_id BIGINT NOT NULL REFERENCES point_of_sale(id),
    variant_value_id BIGINT NOT NULL REFERENCES variant_value(id),
    -- ENTREE (reception), VENTE, CASSE (pate dechiree, abimee), ANNULATION (rendue par
    -- un ticket annule), REMISE_A_ZERO (cloture journaliere).
    movement_type VARCHAR(20) NOT NULL,
    -- Signee : ce qui a ete ajoute (positif) ou retire (negatif).
    quantity NUMERIC(12,3) NOT NULL,
    -- Le compteur APRES le mouvement, fige. Recalculer l'historique a partir des seuls
    -- deltas obligerait a relire toute la journee pour repondre a « il restait combien
    -- a 19 h ? ».
    resulting NUMERIC(12,3) NOT NULL,
    order_id BIGINT REFERENCES sale_order(id) ON DELETE SET NULL,
    user_id BIGINT REFERENCES app_user(id),
    comment VARCHAR(300),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_vsm_pos_date ON variant_stock_movement(point_of_sale_id, created_at DESC);
CREATE INDEX ix_vsm_valeur ON variant_stock_movement(variant_value_id, created_at DESC);
