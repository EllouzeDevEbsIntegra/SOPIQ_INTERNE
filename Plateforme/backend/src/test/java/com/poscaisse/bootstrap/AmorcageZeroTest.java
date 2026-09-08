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
 * << Repartir de zero >> : le commercant a deja son catalogue.
 *
 * CE QUE CE TEST PROTEGE. Le piege serait de livrer quand meme la demonstration - 187
 * articles de superette qu'il faudrait effacer un par un avant de saisir les siens - ou,
 * a l'oppose, de ne rien poser du tout : ni caisse, ni compte, ni reglages, et personne
 * ne peut se connecter le premier jour.
 *
 * La bonne reponse est entre les deux : la maison, une caisse, le compte administrateur,
 * les reglages du metier, et un catalogue vide.
 */
@SpringBootTest(properties = {
        "poscaisse.metier.profil=SHOP",
        "poscaisse.metier.enseigne=SUPÉRETTE ESSALEM",
        "poscaisse.demo-data=false"
})
@EnabledIfEnvironmentVariable(named = "POSCAISSE_IT", matches = "true")
class AmorcageZeroTest {

    @Autowired ProductRepo produits;
    @Autowired CompanyRepo societes;
    @Autowired RegisterRepo caisses;
    @Autowired UserRepo comptes;
    @Autowired RoleRepo roles;
    @Autowired PaymentMethodRepo paiements;
    @Autowired IngredientRepo ingredients;
    @Autowired SettingsService reglages;

    @org.springframework.test.context.DynamicPropertySource
    static void baseNeuve(org.springframework.test.context.DynamicPropertyRegistry r) { BaseDeTest.neuve(r, "amorcage_zero"); }

    @Test void leCatalogueEstVideMaisLaCaisseEstUtilisable() {
        assertThat(produits.count()).as("aucun article imposé au commerçant").isZero();

        // Le socle, lui, est indispensable : sans compte ni caisse, personne n'ouvre le matin.
        assertThat(comptes.count()).as("le seul compte administrateur").isEqualTo(1);
        assertThat(caisses.count()).as("une caisse").isEqualTo(1);
        assertThat(roles.count()).as("les rôles").isPositive();
        assertThat(paiements.count()).as("les moyens de paiement").isPositive();

        /*
            AUCUN INGREDIENT DE FAST-FOOD.

            Une migration en semait dix dans toute base - Omelette, Thon, Salami, Harissa -
            et une supérette se les voyait proposer sur chaque fiche article. Ils
            appartiennent au métier qui s'en sert, pas au schéma.
        */
        assertThat(ingredients.count()).as("aucun ingrédient imposé à une supérette").isZero();
    }

    @Test void lesReglagesDeLaBoutiqueSontPoses() {
        assertThat(reglages.get(SettingsService.BARCODE_ENABLED)).as("une supérette scanne").isEqualTo("true");
        assertThat(reglages.get(SettingsService.STOCK_MODE)).isEqualTo("total");
        assertThat(reglages.get(SettingsService.STOCK_ENTREE)).as("le stock entre par un achat").isEqualTo("achat");
        assertThat(reglages.get(SettingsService.SERVICE_MODES)).isEqualTo("TAKEAWAY");
    }

    /**
     * L'adresse reste VIDE.
     *
     * Une adresse de demonstration - << 12 Avenue Habib Bourguiba, Tunis >> - imprimee sur
     * les tickets d'un commerce de Sfax est pire qu'une ligne blanche : le client la
     * decouvre le soir meme, sur des tickets deja donnes.
     */
    @Test void aucuneAdresseInventee() {
        assertThat(societes.findAll()).singleElement().satisfies(s -> {
            assertThat(s.getTradeName()).isEqualTo("SUPÉRETTE ESSALEM");
            assertThat(s.getAddress()).isNull();
            assertThat(s.getPhone()).isNull();
            assertThat(s.getTaxId()).isNull();
        });
    }
}
