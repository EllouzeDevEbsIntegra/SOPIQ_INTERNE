/*
    VENDRE AU POIDS.

    Une patisserie vend 300 grammes de baklawa, pas un kilo. Aujourd'hui la caisse ne sait
    compter qu'en unites : un article a 58 dinars le kilo ne se vend qu'au kilo entier, et
    le vendeur doit calculer de tete puis corriger le prix a la main - sur chaque vente,
    devant le client, avec le risque qu'on imagine.

    La quantite etait DEJA decimale (numeric(10,3)) : tout le calcul suit sans changer.
    Ce qui manquait, c'est de savoir QUELS articles se pesent, pour que l'ecran demande un
    poids au lieu d'ajouter << 1 >>, et que le ticket dise << 0,300 kg x 58,000 >>.

    PIECE par defaut : rien ne change pour les articles existants, ni pour les cartes deja
    importees. Un article ne se pese que si quelqu'un l'a decide.
*/
ALTER TABLE product ADD COLUMN unite varchar(10) NOT NULL DEFAULT 'PIECE';

ALTER TABLE product ADD CONSTRAINT ck_product_unite CHECK (unite IN ('PIECE', 'KG', 'LITRE'));

COMMENT ON COLUMN product.unite IS
    'PIECE : se compte. KG / LITRE : se pese ou se mesure, le prix est celui de l''unite.';

/*
    L'unite est RECOPIEE sur la ligne de vente, comme le nom de l'article.

    Passer un article du kilo a la piece l'an prochain ne doit pas reecrire les tickets de
    cette annee : un duplicata reimprime dans six mois doit dire ce qui a ete vendu, et non
    ce que la fiche est devenue depuis.
*/
ALTER TABLE order_line ADD COLUMN unite varchar(10) NOT NULL DEFAULT 'PIECE';
