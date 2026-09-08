-- =====================================================================
--  Le code-barres, et le stock qui se compte PAR ARTICLE.
--
--  POURQUOI UNE AUTRE TABLE QUE << variant_stock >>. Le restaurant compte la
--  PATE : la meme pate sert quarante sandwichs, le compteur est donc pose sur
--  la valeur de variante. La boutique, elle, compte la BOUTEILLE : ce qui
--  s'epuise porte un code-barres et un prix d'achat. Les deux comptages
--  coexistent - un cafe qui vend des bouteilles ET des chichas aura les deux -
--  et ils ne se melangent pas : chacun sa table, chacun son verrou.
--
--  LE CODE-BARRES est unique quand il existe. Deux articles sous le meme code,
--  et le scan devient un tirage au sort ; l'index partiel laisse en revanche
--  autant d'articles sans code qu'on veut - un cafe n'en met nulle part.
-- =====================================================================

ALTER TABLE product ADD COLUMN barcode varchar(64);
ALTER TABLE product ADD COLUMN purchase_price numeric(14,3) NOT NULL DEFAULT 0;
ALTER TABLE product ADD COLUMN stock_managed boolean NOT NULL DEFAULT false;
ALTER TABLE product ADD COLUMN stock_min numeric(14,3) NOT NULL DEFAULT 0;

-- Unique seulement parmi les articles qui en portent un.
CREATE UNIQUE INDEX ux_product_barcode ON product (barcode) WHERE barcode IS NOT NULL;
-- La recherche en caisse tape ici a chaque scan.
CREATE INDEX ix_product_barcode ON product (barcode);

ALTER TABLE product ADD CONSTRAINT ck_product_stock_min CHECK (stock_min >= 0);
ALTER TABLE product ADD CONSTRAINT ck_product_purchase_price CHECK (purchase_price >= 0);

CREATE TABLE product_stock (
    id                bigserial PRIMARY KEY,
    point_of_sale_id  bigint NOT NULL REFERENCES point_of_sale(id),
    product_id        bigint NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    quantity          numeric(14,3) NOT NULL DEFAULT 0,
    updated_at        timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ux_product_stock UNIQUE (point_of_sale_id, product_id)
);

/*
    L'historique. Il repond a la question du soir - << il en manque trois, ou
    sont-elles passees ? >> - et c'est la seule facon de distinguer une vente
    d'une casse ou d'une erreur de saisie. Le prix d'achat est garde sur
    l'entree : c'est lui qui donne la marge reelle, et il change d'un
    approvisionnement a l'autre.
*/
CREATE TABLE product_stock_movement (
    id                bigserial PRIMARY KEY,
    point_of_sale_id  bigint NOT NULL REFERENCES point_of_sale(id),
    product_id        bigint NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    movement_type     varchar(20) NOT NULL,
    quantity          numeric(14,3) NOT NULL,
    resulting         numeric(14,3) NOT NULL,
    unit_cost         numeric(14,3),
    order_id          bigint REFERENCES sale_order(id) ON DELETE SET NULL,
    user_id           bigint REFERENCES app_user(id),
    supplier          varchar(120),
    comment           varchar(300),
    created_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_psm_pos_date ON product_stock_movement (point_of_sale_id, created_at DESC);
CREATE INDEX ix_psm_product ON product_stock_movement (product_id, created_at DESC);
