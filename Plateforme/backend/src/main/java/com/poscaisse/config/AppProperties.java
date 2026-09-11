package com.poscaisse.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration @ConfigurationProperties(prefix = "poscaisse") @Getter @Setter
public class AppProperties {
    private String timezone = "Africa/Tunis";
    /**
     * Poser une carte de demonstration au premier demarrage.
     *
     * A {@code false}, le poste neuf recoit sa maison, une caisse et le compte
     * administrateur, et rien de plus : c'est le << repartir de zero >> du client qui
     * saisira sa propre carte.
     */
    private boolean demoData = true;
    private String corsOrigins;
    private Metier metier = new Metier();
    private Admin admin = new Admin();

    /**
     * Le compte administrateur du tout premier demarrage.
     *
     * Lu UNIQUEMENT quand la base ne contient encore aucun compte. Une caisse en service
     * redemarre sans ces valeurs, et les ignore si elles sont la : changer la variable ne
     * change pas le mot de passe d'un commercant qui a deja le sien.
     */
    @Getter @Setter
    public static class Admin {
        /** Obligatoire sur une base vide, douze caracteres au moins. */
        private String password;
        /**
         * FACULTATIF, et vide par defaut.
         *
         * Un PIN de quatre chiffres sur le compte qui peut tout faire, joignable depuis
         * internet, est une porte a dix mille cles - et le ralentisseur ne fait que
         * ralentir. L'administrateur se connecte par mot de passe ; le PIN est l'outil du
         * caissier, qui le tape cent fois par jour devant un client qui attend.
         */
        private String pin;
    }

    /**
     * Le metier tenu par ce poste.
     *
     * Il n'est lu qu'au tout premier demarrage, sur une base ou aucune societe n'existe
     * encore. Le changer ensuite ne retourne pas un commerce en service.
     */
    @Getter @Setter
    public static class Metier {
        /** RESTO, CAFE, SHOP, VETEMENT, PATISSERIE ou PARFUMERIE. Vide : aucun profil. */
        private String profil;
        /** L'enseigne du client. Vide : celle de la carte de demonstration. */
        private String enseigne;
    }
}
