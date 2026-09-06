-- Deux colonnes reclamees par la preparation d'une carte de 117 lignes.
--
-- 1. L'ABREVIATION DE L'INGREDIENT.
--    Les touches d'ingredients composent deja le nom long (« Omlette Mozarilla Thon »).
--    Le ticket, lui, n'a que 42 colonnes, et le passeur lit vite : il lui faut
--    « Oml Moz Thon ». Sans cette colonne, il faudrait ressaisir a la main le nom court
--    de chaque article - 97 fois, et a chaque ajout ensuite.
--
-- 2. LE PRIX A VERIFIER.
--    Une carte construite par regle contient forcement des prix qui ne viennent pas de
--    la carte du client : deduits d'une soustraction, ou simplement inventes faute de
--    tarif connu. Les noyer dans la liste, c'est les mettre en vente tels quels. Le
--    drapeau les nomme, la liste des articles les montre, et le gerant les eteint un par
--    un a mesure qu'il les confirme.
ALTER TABLE ingredient ADD COLUMN short_name VARCHAR(20);
ALTER TABLE product ADD COLUMN price_to_check BOOLEAN NOT NULL DEFAULT false;

-- Abreviations des ingredients du jeu de depart : le nom court, en clair, pas un code.
UPDATE ingredient SET short_name = 'Oml'  WHERE lower(name) = 'omelette';
UPDATE ingredient SET short_name = 'Thon' WHERE lower(name) = 'thon';
UPDATE ingredient SET short_name = 'Moz'  WHERE lower(name) = 'mozzarella';
UPDATE ingredient SET short_name = 'Sal'  WHERE lower(name) = 'salami';
UPDATE ingredient SET short_name = 'Kwk'  WHERE lower(name) = 'kwika';
UPDATE ingredient SET short_name = 'Esc'  WHERE lower(name) = 'escalope';
UPDATE ingredient SET short_name = 'Frm'  WHERE lower(name) = 'fromage';
