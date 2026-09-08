package com.poscaisse.bootstrap;

import com.poscaisse.config.AppProperties;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Ce que le poste comprend de sa configuration avant meme d'ouvrir une base.
 *
 * Deux decisions se prennent ici, et toutes deux se paient cher si elles sont muettes :
 * quel metier tenir, et sous quelle enseigne imprimer. Un profil mal orthographie ou une
 * enseigne abimee ne doivent pas passer en silence.
 */
class AmorcageMetierTest {

    /** Les trois dependances de service ne servent qu'au chargement de carte : inutiles ici. */
    private AmorcageMetier avec(String profil, String enseigne, boolean demonstration) {
        AppProperties p = new AppProperties();
        p.setDemoData(demonstration);
        p.getMetier().setProfil(profil);
        p.getMetier().setEnseigne(enseigne);
        return new AmorcageMetier(p, null, null, null);
    }

    @Test void unProfilConnuEstReconnu() {
        assertThat(avec("CAFE", null, true).profilConfigure()).isEqualTo(ProfilMetier.CAFE);
        assertThat(avec("patisserie", null, true).profilConfigure()).isEqualTo(ProfilMetier.PATISSERIE);
    }

    /**
     * Un profil inconnu ne fait pas deviner : la caisse demarre sans profil, et le dit.
     * Installer un cafe parce que quelqu'un a tape << CAFFE >> serait pire que ne rien
     * installer du tout.
     */
    @Test void unProfilInconnuNInstalleRien() {
        assertThat(avec("CAFFE", null, true).profilConfigure()).isNull();
        assertThat(avec("", null, true).profilConfigure()).isNull();
        assertThat(avec(null, null, true).profilConfigure()).isNull();
    }

    @Test void lEnseigneDuClientLEmporteSurCelleDeLaDemonstration() {
        assertThat(avec("CAFE", "CAFÉ DES DÉLICES", true).enseigne(ProfilMetier.CAFE)).isEqualTo("CAFÉ DES DÉLICES");
        assertThat(avec("CAFE", "  Chez Slim  ", true).enseigne(ProfilMetier.CAFE)).isEqualTo("Chez Slim");
    }

    @Test void sansEnseigneCEstCelleDuProfil() {
        assertThat(avec("SHOP", null, true).enseigne(ProfilMetier.SHOP)).isEqualTo(ProfilMetier.SHOP.enseigne());
        assertThat(avec("SHOP", "   ", true).enseigne(ProfilMetier.SHOP)).isEqualTo(ProfilMetier.SHOP.enseigne());
    }

    /**
     * L'ENSEIGNE ABIMEE.
     *
     * Une variable d'environnement lue par une machine virtuelle demarree sans langue
     * arrive amputee de ses accents : chaque octet non-ASCII devient un caractere de
     * remplacement. << SUPERETTE >> accentue s'imprimerait alors abime sur tous les
     * tickets du commerce, et personne ne saurait d'ou cela vient.
     *
     * On refuse de l'enregistrer. Le U+FFFD du test n'est pas une curiosite : c'est
     * exactement ce que la machine a produit le jour ou le defaut a ete trouve.
     */
    @Test void uneEnseigneAbimeeEstRefusee() {
        String abimee = "SUP��RETTE ESSALEM";
        assertThat(avec("SHOP", abimee, true).enseigne(ProfilMetier.SHOP))
                .as("on ne grave pas un nom abîmé sur les tickets")
                .isEqualTo(ProfilMetier.SHOP.enseigne());
    }

    @Test void laDemonstrationSuitLeReglageDuPoste() {
        assertThat(avec("CAFE", null, true).avecDemonstration()).isTrue();
        assertThat(avec("CAFE", null, false).avecDemonstration()).isFalse();
    }
}
