/*
    LES CAISSES DE DEMONSTRATION.

    Une par metier, pour montrer a un prospect ce qu'il achete. Elles ne sont pas des
    clients : elles n'ont ni abonnement, ni licence, ni facture - seulement un nom, une
    base, et un interrupteur.

    POURQUOI UNE TABLE PLUTOT QU'UNE LISTE DANS LE CODE. L'etat << allumee depuis 14h32 >>
    doit survivre a un redemarrage du back-office : sinon, une demo restee allumee un
    vendredi soir tournerait tout le week-end sans que rien ne sache qu'il faut l'eteindre.

    << posdemo_ >> N'EST PAS UN PREFIXE DECORATIF. C'est la frontiere de securite : le seul
    endroit du logiciel qui SUPPRIME une base refuse tout nom qui ne commence pas par la.
    La base d'un client s'appelle << pos_cli0001_cafe >> et ne peut donc jamais y passer,
    meme si quelqu'un se trompait de bouton.
*/
CREATE TABLE demo (
    module        varchar(20) PRIMARY KEY,
    sous_domaine  varchar(80)  NOT NULL UNIQUE,
    base_nom      varchar(80)  NOT NULL UNIQUE,
    port          int          NOT NULL UNIQUE,
    allumee       boolean      NOT NULL DEFAULT false,
    demarree_le   timestamptz,
    eteinte_le    timestamptz,
    -- Qui a appuye, pour que le journal dise autre chose que << quelqu'un >>.
    demarree_par  varchar(60),
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT ck_demo_base CHECK (base_nom LIKE 'posdemo\_%'),
    CONSTRAINT ck_demo_port CHECK (port BETWEEN 1024 AND 65535)
);

COMMENT ON COLUMN demo.allumee IS
    'Le processus tourne. Eteindre remet la base a son etat de demonstration initial.';

/*
    Les six metiers, et les ports qu'ils occupent en local.

    8121-8126 : au-dessus de la plage des clients (8101+) et loin des applications deja
    installees sur la machine. Aucun de ces ports n'est ouvert sur l'exterieur - nginx est
    le seul a s'y adresser.
*/
INSERT INTO demo (module, sous_domaine, base_nom, port) VALUES
    ('RESTO',      'demo-resto',      'posdemo_resto',      8121),
    ('CAFE',       'demo-cafe',       'posdemo_cafe',       8122),
    ('SHOP',       'demo-shop',       'posdemo_shop',       8123),
    ('VETEMENT',   'demo-vetement',   'posdemo_vetement',   8124),
    ('PATISSERIE', 'demo-patisserie', 'posdemo_patisserie', 8125),
    ('PARFUMERIE', 'demo-parfumerie', 'posdemo_parfumerie', 8126);
