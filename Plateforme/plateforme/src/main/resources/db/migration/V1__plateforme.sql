-- =====================================================================
--  Le back-office editeur : qui sont nos clients, ce qu'ils ont achete,
--  ce qu'ils nous doivent.
--
--  CETTE BASE NE CONTIENT AUCUNE DONNEE DE VENTE. Les tickets, les
--  articles et les caisses vivent dans la base du client, une par client.
--  Ici on ne trouve que le contrat : c'est ce qui permet d'ouvrir ce
--  back-office a un commercial sans lui ouvrir la comptabilite de trois
--  cents commercants.
-- =====================================================================

CREATE TABLE editeur_user (
    id            bigserial PRIMARY KEY,
    username      varchar(60) NOT NULL UNIQUE,
    full_name     varchar(120) NOT NULL,
    email         varchar(160),
    password_hash varchar(120) NOT NULL,
    role          varchar(20) NOT NULL,          -- ADMIN | COMMERCIAL | SUPPORT
    active        boolean NOT NULL DEFAULT true,
    last_login_at timestamptz,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app_secret (
    key        varchar(60) PRIMARY KEY,
    value      text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

/*
    Le client, c'est la MAISON : une raison sociale, un patron, une ville.
    Elle peut avoir plusieurs abonnements - deux restaurants, ou un restaurant
    et un cafe - et c'est elle qu'on facture.
*/
CREATE TABLE client (
    id               bigserial PRIMARY KEY,
    code             varchar(20) NOT NULL UNIQUE,   -- CLI-0001, lisible au telephone
    raison_sociale   varchar(160) NOT NULL,
    enseigne         varchar(160),
    contact_nom      varchar(120),
    contact_tel      varchar(40),
    contact_email    varchar(160),
    ville            varchar(80),
    adresse          varchar(300),
    matricule_fiscal varchar(40),
    statut           varchar(20) NOT NULL DEFAULT 'PROSPECT',  -- PROSPECT | ACTIF | SUSPENDU | RESILIE
    notes            varchar(1000),
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_client_statut ON client (statut);

/*
    L'abonnement : un METIER, un nombre de caisses, une echeance.

    C'est lui qui porte le module vendu - et donc la carte de demonstration
    installee a la souscription - et l'instance qui a ete provisionnee.
*/
CREATE TABLE abonnement (
    id             bigserial PRIMARY KEY,
    client_id      bigint NOT NULL REFERENCES client(id) ON DELETE CASCADE,
    module         varchar(20) NOT NULL,          -- RESTO | CAFE | SHOP | VETEMENT | PATISSERIE | PARFUMERIE
    formule        varchar(20) NOT NULL DEFAULT 'MENSUEL',   -- MENSUEL | ANNUEL
    nb_caisses     int NOT NULL DEFAULT 1,
    prix_mensuel   numeric(12,3) NOT NULL DEFAULT 0,
    debut_le       date NOT NULL,
    fin_le         date,
    statut         varchar(20) NOT NULL DEFAULT 'ACTIF',     -- ACTIF | SUSPENDU | TERMINE
    -- Ce que le provisionnement a cree, et quand il a tourne.
    base_nom       varchar(80),
    url_client     varchar(200),
    version        varchar(40),
    provisionne_le timestamptz,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_abonnement_caisses CHECK (nb_caisses >= 1),
    CONSTRAINT ck_abonnement_prix CHECK (prix_mensuel >= 0)
);
CREATE INDEX ix_abonnement_client ON abonnement (client_id);
CREATE INDEX ix_abonnement_statut ON abonnement (statut);

/*
    La licence : ce que le poste presente pour avoir le droit d'ouvrir.

    Elle est verifiee AU SERVEUR, et non par une cle posee sur le poste qui se
    copierait d'une machine a l'autre. Le compteur d'activations dit combien de
    caisses s'en servent : au-dela du nombre vendu, la suivante est refusee.
*/
CREATE TABLE licence (
    id             bigserial PRIMARY KEY,
    abonnement_id  bigint NOT NULL REFERENCES abonnement(id) ON DELETE CASCADE,
    cle            varchar(40) NOT NULL UNIQUE,
    postes_max     int NOT NULL DEFAULT 1,
    expire_le      date,
    revoquee       boolean NOT NULL DEFAULT false,
    derniere_verif timestamptz,
    created_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_licence_postes CHECK (postes_max >= 1)
);

/*
    Une activation = une caisse qui s'est presentee avec la licence.
    L'empreinte identifie la machine ; deux ouvertures sur le meme poste ne
    comptent donc qu'une fois, et un poste remplace se voit.
*/
CREATE TABLE licence_activation (
    id           bigserial PRIMARY KEY,
    licence_id   bigint NOT NULL REFERENCES licence(id) ON DELETE CASCADE,
    empreinte    varchar(120) NOT NULL,
    libelle      varchar(120),
    premiere_le  timestamptz NOT NULL DEFAULT now(),
    derniere_le  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ux_activation UNIQUE (licence_id, empreinte)
);

/*
    La facture. Pas de paiement en ligne : on emet, le client vire ou depose,
    et on saisit le reglement. Le solde se DEDUIT - facture moins reglements -
    plutot que d'etre stocke : un solde ecrit quelque part finit toujours par
    ne plus correspondre a son detail.
*/
CREATE TABLE facture (
    id             bigserial PRIMARY KEY,
    client_id      bigint NOT NULL REFERENCES client(id) ON DELETE CASCADE,
    abonnement_id  bigint REFERENCES abonnement(id) ON DELETE SET NULL,
    numero         varchar(30) NOT NULL UNIQUE,
    periode_debut  date NOT NULL,
    periode_fin    date NOT NULL,
    montant        numeric(12,3) NOT NULL,
    emise_le       date NOT NULL,
    echeance_le    date NOT NULL,
    statut         varchar(20) NOT NULL DEFAULT 'EMISE',  -- EMISE | PAYEE | ANNULEE
    libelle        varchar(300),
    created_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_facture_montant CHECK (montant >= 0),
    CONSTRAINT ck_facture_periode CHECK (periode_fin >= periode_debut)
);
CREATE INDEX ix_facture_client ON facture (client_id, echeance_le);
CREATE INDEX ix_facture_statut ON facture (statut);

CREATE TABLE reglement (
    id          bigserial PRIMARY KEY,
    facture_id  bigint NOT NULL REFERENCES facture(id) ON DELETE CASCADE,
    montant     numeric(12,3) NOT NULL,
    recu_le     date NOT NULL,
    moyen       varchar(20) NOT NULL,          -- VIREMENT | CHEQUE | ESPECES | AUTRE
    reference   varchar(80),
    note        varchar(300),
    saisi_par   bigint REFERENCES editeur_user(id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_reglement_montant CHECK (montant > 0)
);
CREATE INDEX ix_reglement_facture ON reglement (facture_id);

/*
    Le journal : qui a fait quoi. Sur une plateforme qui tient les contrats de
    trois cents commercants, savoir qui a suspendu un client - et quand -
    n'est pas un luxe.
*/
CREATE TABLE journal_editeur (
    id          bigserial PRIMARY KEY,
    user_id     bigint REFERENCES editeur_user(id),
    username    varchar(60),
    action      varchar(60) NOT NULL,
    cible_type  varchar(40),
    cible_id    bigint,
    details     varchar(600),
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_journal_date ON journal_editeur (created_at DESC);
