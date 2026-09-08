/*
    UNE PHOTO PAR VERSION.

    L'article porte deja une photo, et la grille des versions porte deja un prix par
    version. Il manquait le pendant visuel : un T-shirt noir et un T-shirt blanc ne se
    reconnaissent pas a leur nom sur un ecran tactile, et une pate cereale ne ressemble
    pas a une pate normale.

    FACULTATIF, ET C'EST LA REGLE ENTIERE. La caisse affiche la photo de la version si
    elle existe ; sinon celle de l'article ; sinon rien. Un commerce qui ne veut qu'une
    seule photo par article n'a rien a faire, et rien ne change pour lui.

    Meme rangement que la photo de l'article : une image encodee dans la colonne, pas un
    chemin vers un fichier. Une caisse installee dans un commerce n'a pas de serveur de
    fichiers a cote d'elle, et une photo perdue vaut moins qu'une photo lourde.
*/
ALTER TABLE product_variant_price ADD COLUMN image_url text;

COMMENT ON COLUMN product_variant_price.image_url IS
    'Photo propre a cette version. Vide : celle de l''article, ou rien.';
