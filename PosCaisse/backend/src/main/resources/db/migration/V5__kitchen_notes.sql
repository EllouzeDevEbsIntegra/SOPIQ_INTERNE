-- Remarques de cuisine proposees au caissier : « sans oignon », « bien cuit »…
-- Le texte retenu reste copie dans order_line.note plutot que reference par une cle
-- etrangere : un ticket deja imprime doit garder ce qui a ete demande ce jour-la, meme
-- si la remarque est renommee ou supprimee ensuite.
CREATE TABLE kitchen_note (
    id BIGSERIAL PRIMARY KEY,
    label VARCHAR(80) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_kitchen_note_order ON kitchen_note(sort_order, id);

-- Un point de depart courant en restauration rapide ; tout est modifiable ou supprimable
-- depuis le back-office.
INSERT INTO kitchen_note (label, sort_order) VALUES
    ('Sans oignon', 1), ('Sans sauce', 2), ('Sans salade', 3), ('Sans piquant', 4),
    ('Bien cuit', 5), ('Peu cuit', 6), ('Sauce à part', 7), ('Emballer séparément', 8);
