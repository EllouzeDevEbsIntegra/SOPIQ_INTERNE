-- =====================================================================
--  Les secrets propres a l'installation.
--
--  POURQUOI UNE TABLE A PART. La cle qui signe les jetons ne doit sortir
--  d'aucun ecran ni d'aucune API. Rangee dans << app_setting >>, elle serait
--  servie par GET /api/settings avec les autres reglages - une ligne de plus
--  dans une reponse que personne ne relit. Ici, aucun endpoint ne la lit :
--  c'est le seul moyen sur de garantir qu'elle ne fuit pas par distraction.
--
--  POURQUOI EN BASE ET NON DANS UN FICHIER. Le secret doit survivre au
--  redemarrage, sinon tous les caissiers sont deconnectes a chaque mise a
--  jour ; et il doit etre PROPRE a l'installation, sinon un secret livre avec
--  le logiciel permettrait a quiconque a lu le code de fabriquer un jeton
--  valide pour n'importe quel client.
-- =====================================================================

CREATE TABLE app_secret (
    key        varchar(60) PRIMARY KEY,
    value      text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
