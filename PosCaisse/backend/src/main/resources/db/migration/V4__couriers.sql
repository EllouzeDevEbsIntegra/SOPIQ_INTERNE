-- Livreurs : chacun a un compte tenu exactement comme celui d'un client.
CREATE TABLE courier (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    phone VARCHAR(40),
    note VARCHAR(255),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_courier_name ON courier(name);

-- Un ticket en livraison est confie a un livreur : c'est lui qui detient l'argent
-- entre la sortie de la caisse et le versement, donc c'est son compte qui est debite.
ALTER TABLE sale_order ADD COLUMN courier_id BIGINT REFERENCES courier(id);
CREATE INDEX ix_sale_order_courier ON sale_order(courier_id);

-- Regler un compte client et regler un compte livreur, c'est le meme mouvement :
-- une seule table les porte. Chaque ligne reference exactement un compte, et la
-- contrainte l'impose plutot que de s'en remettre au code applicatif.
ALTER TABLE customer_payment RENAME TO account_payment;
ALTER TABLE account_payment RENAME CONSTRAINT ck_customer_payment_amount TO ck_account_payment_amount;
ALTER TABLE account_payment ALTER COLUMN customer_id DROP NOT NULL;
ALTER TABLE account_payment ADD COLUMN courier_id BIGINT REFERENCES courier(id);
ALTER TABLE account_payment ADD CONSTRAINT ck_account_payment_party
    CHECK ((customer_id IS NULL) <> (courier_id IS NULL));
CREATE INDEX ix_account_payment_courier ON account_payment(courier_id, paid_at);
