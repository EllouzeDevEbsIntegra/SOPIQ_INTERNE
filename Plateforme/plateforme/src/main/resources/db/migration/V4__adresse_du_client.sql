/*
    L'ADRESSE DU CLIENT : UN SOUS-DOMAINE ET UN PORT.

    Le provisionnement preparait la base et rendait une commande de lancement, et s'arretait
    la. Il manquait ce qui fait qu'un client peut OUVRIR SA CAISSE : une adresse a taper le
    matin. Les demonstrations en avaient une depuis V3, les clients non - la colonne
    << url_client >> existait depuis V1 et n'a jamais ete remplie par personne.

    LE PORT EST UNIQUE, ET C'EST LA COLONNE QUI LE GARANTIT. Sans elle, deux caisses
    ouvertes le meme jour recevraient le meme numero : la seconde ne demarrerait pas, avec
    un << Address already in use >> dans un journal que personne ne lit, et le commercant
    trouverait une adresse qui ne repond pas. Une contrainte de base est le seul endroit ou
    cette promesse tient meme si deux personnes provisionnent en meme temps.

    LA PLAGE 8101-8120 EVITE CELLE DES DEMOS (8121-8126, voir V3) et celle des applications
    deja installees sur la machine. Vingt caisses est un plafond large pour un serveur qui
    en heberge quatre a six avant de manquer de memoire ; le jour ou il faut plus, c'est un
    reglage - plateforme.provisionnement.port-max - et non une migration.

    LE SOUS-DOMAINE EST UNIQUE AUSSI, evidemment : deux clients a la meme adresse, c'est un
    client qui ouvre la caisse de l'autre.
*/
ALTER TABLE abonnement
    ADD COLUMN sous_domaine varchar(63),
    ADD COLUMN port         int;

CREATE UNIQUE INDEX ux_abonnement_sous_domaine ON abonnement (sous_domaine) WHERE sous_domaine IS NOT NULL;
CREATE UNIQUE INDEX ux_abonnement_port         ON abonnement (port)         WHERE port IS NOT NULL;

/*
    Les memes gardes que pour un nom de base : ce texte finit dans un nom de fichier, dans
    une unite systemd et dans une directive nginx. Il n'a le droit de contenir que des
    minuscules, des chiffres et des tirets, sans tiret au bord.
*/
ALTER TABLE abonnement
    ADD CONSTRAINT ck_abonnement_sous_domaine
        CHECK (sous_domaine IS NULL OR sous_domaine ~ '^[a-z0-9]([a-z0-9-]{1,38}[a-z0-9])?$'),
    ADD CONSTRAINT ck_abonnement_port
        CHECK (port IS NULL OR port BETWEEN 1024 AND 65535);

COMMENT ON COLUMN abonnement.sous_domaine IS
    'Le nom que le client tape le matin : <sous_domaine>.pos.ebs-integra.com.';
COMMENT ON COLUMN abonnement.port IS
    'Le port local de sa caisse. Jamais ouvert sur l''exterieur : nginx est le seul a s''y adresser.';
