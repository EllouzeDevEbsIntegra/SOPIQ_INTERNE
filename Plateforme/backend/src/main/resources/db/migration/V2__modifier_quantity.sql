-- Une option peut être ajoutée plusieurs fois à la même ligne lorsque son
-- groupe est sans maximum (max_select = 0) : on stocke la quantité plutôt que
-- de répéter des lignes identiques, pour que le ticket dise « 3 x Mozarilla »
-- et non trois fois la même mention.
ALTER TABLE order_line_modifier ADD COLUMN quantity INT NOT NULL DEFAULT 1;
ALTER TABLE order_line_modifier ADD CONSTRAINT ck_olm_quantity CHECK (quantity > 0);
