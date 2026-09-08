package com.poscaisse.plateforme.domain;

public class Enums {

    /** Les metiers vendus. Chacun apporte ses reglages et sa carte de demonstration. */
    public enum Module { RESTO, CAFE, SHOP, VETEMENT, PATISSERIE, PARFUMERIE }

    /**
     * Ou en est le client.
     *
     * SUSPENDU n'est pas RESILIE : la caisse passe en lecture seule, rien n'est efface.
     * Couper l'acces a ses propres donnees a un commercant qui a un impaye serait une
     * faute - il doit pouvoir sortir son historique quoi qu'il arrive.
     */
    public enum StatutClient { PROSPECT, ACTIF, SUSPENDU, RESILIE }

    public enum StatutAbonnement { ACTIF, SUSPENDU, TERMINE }

    public enum Formule { MENSUEL, ANNUEL }

    public enum StatutFacture { EMISE, PAYEE, ANNULEE }

    public enum MoyenReglement { VIREMENT, CHEQUE, ESPECES, AUTRE }

    /**
     * Qui fait quoi chez nous.
     *
     * COMMERCIAL cree des clients et des abonnements mais ne touche ni aux reglements ni
     * aux comptes ; SUPPORT regarde sans rien changer. Le detail des droits est dans
     * {@link Role#peut}.
     */
    public enum Role { ADMIN, COMMERCIAL, SUPPORT;

        public boolean peut(Droit d) {
            return switch (this) {
                case ADMIN -> true;
                case COMMERCIAL -> d != Droit.UTILISATEURS && d != Droit.ENCAISSER;
                case SUPPORT -> d == Droit.LIRE;
            };
        }
    }

    /** Ce qu'on peut faire, dit en quatre mots plutot qu'en vingt permissions. */
    public enum Droit { LIRE, GERER_CLIENTS, ENCAISSER, UTILISATEURS }
}
