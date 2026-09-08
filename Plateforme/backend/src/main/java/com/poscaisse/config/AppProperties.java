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
