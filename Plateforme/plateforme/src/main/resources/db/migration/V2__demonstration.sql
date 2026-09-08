/*
    Le client part-il d'une carte de demonstration, ou de rien ?

    C'est une decision commerciale, prise au moment de la vente, et elle doit survivre au
    provisionnement : quand on rejoue la commande de lancement six mois plus tard - poste
    remplace, disque change - il faut retrouver ce qui avait ete promis. Une valeur qu'on
    ne garde pas est une valeur qu'on redemandera au client.

    Vrai par defaut : c'est ce qui a ete vendu jusqu'ici, et ce qu'un commerce veut presque
    toujours - une caisse qui montre quelque chose des la premiere ouverture.
*/
ALTER TABLE abonnement ADD COLUMN avec_demonstration boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN abonnement.avec_demonstration IS
    'Charger la carte de demonstration du module au premier demarrage de la caisse.';
