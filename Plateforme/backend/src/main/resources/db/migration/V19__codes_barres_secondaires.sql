/*
    UN ARTICLE, PLUSIEURS CODES-BARRES.

    La colonne << barcode >> n'en portait qu'un. En superette, le meme produit arrive avec
    des EAN differents selon le fournisseur, le format ou l'annee : l'export du premier
    client reel en compte 885 pour 395 articles, jusqu'a QUATORZE pour un seul. Un article
    qui ne passe pas a la douchette, c'est un caissier qui cherche a la main pendant qu'une
    file attend - le defaut le plus visible qu'une caisse puisse avoir.

    POURQUOI UNE COLONNE ET NON UNE TABLE. Une table de liaison serait plus orthodoxe. Elle
    couterait une jointure sur un catalogue lu a chaque ouverture de caisse, un ecran de
    plus a maintenir, et surtout elle ne se defait pas : revenir en arriere sur une colonne
    de texte, c'est un ALTER TABLE DROP COLUMN. Le choix est assume et reversible.

    LE FORMAT : les codes separes par une espace, et rien d'autre. Un code-barres n'a que
    des chiffres, il n'y a donc ni echappement, ni guillemet, ni virgule decimale a
    craindre - c'est ce qui rend ce stockage sur - et string_to_array redonne la liste
    quand on en a besoin.

    L'INDEX N'EST PAS UNE PRECAUTION DE STYLE. Sans lui, chaque scan qui ne trouve pas de
    code principal parcourt la table entiere. Sur trois cents articles cela ne se voit pas ;
    sur les quinze mille d'une superette, le caissier attend devant le client. Un index GIN
    sur le decoupage rend la recherche immediate, et string_to_array est IMMUTABLE, donc
    indexable.
*/
ALTER TABLE product ADD COLUMN barcodes_secondaires text;

COMMENT ON COLUMN product.barcodes_secondaires IS
    'Codes-barres supplementaires de cet article, separes par une espace. Le code principal reste dans barcode.';

CREATE INDEX ix_product_codes_secondaires
    ON product USING gin (string_to_array(barcodes_secondaires, ' '));
