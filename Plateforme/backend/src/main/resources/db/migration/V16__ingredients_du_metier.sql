/*
    LES INGREDIENTS APPARTIENNENT AU METIER, PAS AU SCHEMA.

    V6 semait dix ingredients de fast-food - Omelette, Thon, Salami, Harissa - dans toute
    base creee, parce qu'a l'epoque la caisse ne tenait qu'un seul commerce. Depuis qu'elle
    en tient six, une patisserie ouvre la fiche de sa baklawa et se voit proposer du salami,
    et une parfumerie de la harissa. Ce n'est pas une faute de gout : c'est une liste qui
    ne veut rien dire au commercant, sur l'ecran ou il saisit sa carte.

    On les retire - MAIS SEULEMENT SI PERSONNE NE S'EN SERT. La condition n'est pas une
    precaution de style : sur la base d'un fast-food en service, ces dix mots composent le
    nom des articles et filtrent l'ecran de vente. Les effacer la-bas serait detruire son
    travail pour corriger le notre.

    Le profil RESTO les repose ensuite lui-meme au premier demarrage, avec sa carte : c'est
    la qu'ils ont toujours eu leur place.
*/
DELETE FROM ingredient i
 WHERE i.name IN ('Omelette', 'Thon', 'Mozzarella', 'Salami', 'Kwika',
                  'Escalope', 'Viande hachée', 'Fromage', 'Harissa', 'Salade')
   AND NOT EXISTS (SELECT 1 FROM product_ingredient pi WHERE pi.ingredient_id = i.id);
