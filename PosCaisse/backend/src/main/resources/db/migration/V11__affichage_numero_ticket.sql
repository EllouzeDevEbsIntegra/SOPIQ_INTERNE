-- Ce qui s'ecrit sur le ticket, distinct de ce qui est enregistre.
--
-- La reference d'une vente peut etre longue - point de vente, caisse, date, compteur -
-- parce qu'elle doit rester unique et parlante pour la comptabilite. Le client, lui, n'a
-- pas a lire tout cela : il lui faut un numero court, celui qu'il annoncera au comptoir.
-- Les deux sont desormais separes : la reference reste en base, l'affichage est ce qui
-- part a l'impression.
--
-- L'affichage est ENREGISTRE sur la vente, non recalcule a la demande : une reimpression
-- six mois plus tard doit ressortir le numero que le client a garde dans sa poche, meme
-- si le format d'affichage a change entre-temps.
ALTER TABLE sale_order ADD COLUMN ticket_display VARCHAR(60);

-- Les ventes d'avant portaient leur reference sur le papier : c'est donc elle leur
-- affichage, et une reimpression rendra exactement le meme ticket.
UPDATE sale_order SET ticket_display = ticket_number WHERE ticket_number IS NOT NULL;

-- Vide par defaut : sans reglage, le ticket continue de montrer sa reference entiere.
INSERT INTO app_setting (setting_key, setting_value, updated_at)
VALUES ('ticket.displayPattern', '', now())
ON CONFLICT (setting_key) DO NOTHING;
