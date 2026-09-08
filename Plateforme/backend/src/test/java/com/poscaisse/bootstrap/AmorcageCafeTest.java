package com.poscaisse.bootstrap;

import com.poscaisse.BaseDeTest;
import com.poscaisse.repository.*;
import com.poscaisse.service.SettingsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Un poste neuf qui devient un cafe, tout seul, au premier demarrage.
 *
 * CE QUE CE TEST PROTEGE. La promesse commerciale de la plateforme tient en une ligne :
 * vendre un abonnement suffit a ouvrir un client. Si ce demarrage-la se casse, le client
 * ouvre son commerce le matin sur une caisse vide, sans carte et sans reglages, et il faut
 * envoyer quelqu'un. C'est le scenario le plus cher a rater de tout le projet.
 *
 * Il demarre une vraie application sur une base neuve, comme le fera la machine du client.
 */
@SpringBootTest(properties = {
        "poscaisse.metier.profil=CAFE",
        "poscaisse.metier.enseigne=CAFÉ DES DÉLICES",
        "poscaisse.demo-data=true"
})
@EnabledIfEnvironmentVariable(named = "POSCAISSE_IT", matches = "true")
class AmorcageCafeTest {

    @Autowired ProductRepo produits;
    @Autowired CategoryRepo categories;
    @Autowired CompanyRepo societes;
    @Autowired RegisterRepo caisses;
    @Autowired UserRepo comptes;
    @Autowired SettingsService reglages;

    @org.springframework.test.context.DynamicPropertySource
    static void baseNeuve(org.springframework.test.context.DynamicPropertyRegistry r) { BaseDeTest.neuve(r, "amorcage_cafe"); }

    @Test void leCafeSInstalleSeul() {
        // La carte du metier, chargee depuis le JAR sans que personne lance de script.
        assertThat(produits.count()).as("articles de la carte café").isEqualTo(112);
        assertThat(categories.count()).as("catégories").isEqualTo(11);

        // Les reglages du metier, ECRITS en base : le gerant doit les voir et pouvoir les changer.
        assertThat(reglages.get(SettingsService.SERVICE_MODES)).isEqualTo("DINE_IN,TAKEAWAY");
        assertThat(reglages.get(SettingsService.DEFAULT_SERVICE_MODE)).isEqualTo("DINE_IN");
        assertThat(reglages.get(SettingsService.BARCODE_ENABLED)).as("un café ne scanne pas").isEqualTo("false");
        assertThat(reglages.get(SettingsService.STOCK_MODE)).isEqualTo("partiel");
        assertThat(reglages.get(SettingsService.STOCK_RUPTURE)).isEqualTo("avertir");
        assertThat(reglages.get(SettingsService.QUICK_CASH)).as("le panier d'un café tient en petites coupures").isEqualTo("1,2,5,10");

        // L'enseigne du client, accents compris, et non celle de la demonstration.
        assertThat(societes.findAll()).singleElement()
                .satisfies(s -> assertThat(s.getTradeName()).isEqualTo("CAFÉ DES DÉLICES"));

        // La demonstration montre les roles : deux caisses, un manager, trois caissiers.
        assertThat(caisses.count()).isEqualTo(2);
        assertThat(comptes.count()).isEqualTo(5);
    }

    /** La caisse ne recoit que ce qui la regarde - et le metier en fait partie. */
    @Test void laCaisseRecoitLesReglagesDuMetier() {
        assertThat(reglages.pourLaCaisse())
                .containsEntry(SettingsService.BARCODE_ENABLED, "false")
                .containsEntry(SettingsService.STOCK_MODE, "partiel")
                .doesNotContainKey(SettingsService.MARGIN_PERCENT);
    }
}
