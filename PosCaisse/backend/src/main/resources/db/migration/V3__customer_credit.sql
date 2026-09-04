-- Crédit client : un ticket peut être encaissé « à crédit », c'est-à-dire porté
-- au compte d'un client nommé, puis réglé plus tard par un ou plusieurs
-- règlements. Le solde n'est pas stocké : il se calcule à partir des deux
-- mouvements, ce qui évite toute dérive entre le solde et son détail.

-- Le moyen de paiement « Crédit client » n'est volontairement pas inséré ici :
-- les migrations s'exécutent avant l'amorçage des données de base, qui ne crée
-- les moyens de paiement que si la table est vide. L'insérer ici priverait une
-- installation neuve des espèces et de la carte. C'est l'amorçage qui s'en charge.

CREATE TABLE customer_payment (
    id BIGSERIAL PRIMARY KEY,
    number VARCHAR(30) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL REFERENCES customer(id),
    payment_method_id BIGINT NOT NULL REFERENCES payment_method(id),
    amount NUMERIC(14,3) NOT NULL,
    paid_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    user_id BIGINT NOT NULL REFERENCES app_user(id),
    session_id BIGINT REFERENCES register_session(id),
    note VARCHAR(255),
    CONSTRAINT ck_customer_payment_amount CHECK (amount > 0)
);
CREATE INDEX ix_customer_payment_customer ON customer_payment(customer_id, paid_at);

-- Installations déjà en service : les rôles existent, l'amorçage ne les recrée
-- pas, et personne n'aurait la permission d'ouvrir les comptes clients.
INSERT INTO role_permission (role_id, permission)
SELECT r.id, 'CUSTOMER_CREDIT' FROM role r
 WHERE r.code IN ('ADMIN', 'MANAGER')
   AND NOT EXISTS (SELECT 1 FROM role_permission rp
                    WHERE rp.role_id = r.id AND rp.permission = 'CUSTOMER_CREDIT');
