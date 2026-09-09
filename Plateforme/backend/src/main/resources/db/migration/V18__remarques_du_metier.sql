/*
    LES REMARQUES APPARTIENNENT AU METIER, PAS AU SCHEMA.

    Meme histoire que les mots-cles en V16, et meme correction. V5 semait huit remarques de
    restauration rapide - << Sans oignon >>, << Bien cuit >>, << Sauce a part >> - dans
    TOUTE base creee, parce qu'a l'epoque la caisse ne tenait qu'un seul commerce. Depuis
    qu'elle en tient six, un parfumeur ouvre l'ecran des remarques et se voit proposer de
    servir la sauce a part.

    On les retire - MAIS SEULEMENT SI PERSONNE NE S'EN SERT. Sur la base d'un fast-food en
    service, ces huit phrases sont les touches que le caissier appuie toute la journee ; les
    effacer la-bas serait detruire son travail pour corriger le notre.

    << S'en servir >> se lit dans les tickets deja passes, et pas ailleurs : le texte d'une
    remarque est COPIE dans la ligne de commande au moment de la vente, jamais reference par
    une cle etrangere - un ticket imprime doit garder ce qui a ete demande ce jour-la, meme
    si la remarque est renommee ou supprimee ensuite (voir V5). Il n'y a donc aucun lien a
    interroger, et c'est le texte lui-meme qu'on cherche.

    Une ligne peut porter PLUSIEURS remarques, plus un texte libre, assemblees par << , >> :
    on redecoupe donc la note sur ce separateur et on compare chaque morceau entier. Un
    LIKE sur un fragment se tromperait dans les deux sens - << Sans sauce >> se trouve dans
    << Sans sauce piquante >>, ecrit a la main.

    Le profil RESTO les repose ensuite lui-meme au premier demarrage, avec sa carte : c'est
    la qu'elles ont toujours eu leur place.
*/
DELETE FROM kitchen_note k
 WHERE k.label IN ('Sans oignon', 'Sans sauce', 'Sans salade', 'Sans piquant',
                   'Bien cuit', 'Peu cuit', 'Sauce à part', 'Emballer séparément')
   AND NOT EXISTS (
        SELECT 1 FROM order_line l, unnest(string_to_array(l.note, ', ')) AS morceau
         WHERE l.note IS NOT NULL AND morceau = k.label);
