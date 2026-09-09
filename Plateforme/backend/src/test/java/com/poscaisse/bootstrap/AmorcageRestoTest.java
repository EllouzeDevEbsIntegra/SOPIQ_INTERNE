package com.poscaisse.bootstrap;

import com.poscaisse.BaseDeTest;
import com.poscaisse.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LE RESTO GARDE CE QUE LES CINQ AUTRES METIERS N'ONT PLUS.
 *
 * Les mots-cles (<< Omelette >>, << Salami >>) et les remarques (<< Sans oignon >>,
 * << Sauce a part >>) etaient poses par des migrations, donc dans TOUTE base : une
 * patisserie se voyait proposer du salami, un parfumeur de servir la sauce a part. Deux
 * migrations les retirent maintenant, et c'est le profil RESTO qui les repose avec sa
 * carte - la ou ils ont toujours eu leur place.
 *
 * CE TEST EST LA MOITIE QUI MANQUE. Les scenarios cafe et superette prouvent que les cinq
 * autres metiers demarrent l'ecran vide ; sans celui-ci, une correction trop large -
 * effacer sans reposer - passerait tous les tests en laissant un fast-food neuf sans
 * aucune de ses touches, et cela ne se verrait qu'a l'ouverture d'un client.
 */
@SpringBootTest(properties = {
        "poscaisse.metier.profil=RESTO",
        "poscaisse.demo-data=true"
})
@EnabledIfEnvironmentVariable(named = "POSCAISSE_IT", matches = "true")
class AmorcageRestoTest {

    @Autowired IngredientRepo motsCles;
    @Autowired KitchenNoteRepo remarques;
    @Autowired ProductRepo produits;

    @org.springframework.test.context.DynamicPropertySource
    static void baseNeuve(org.springframework.test.context.DynamicPropertyRegistry r) { BaseDeTest.neuve(r, "amorcage_resto"); }

    @Test void leRestoRetrouveSesMotsClesEtSesRemarques() {
        assertThat(produits.count()).as("la carte du fast-food est posée").isPositive();

        assertThat(motsCles.count()).as("les dix mots-clés du fast-food").isEqualTo(10);
        assertThat(motsCles.findAll()).extracting("name").contains("Omelette", "Thon", "Salami", "Harissa");

        assertThat(remarques.count()).as("les huit remarques du fast-food").isEqualTo(8);
        assertThat(remarques.findAll()).extracting("label")
                .contains("Sans oignon", "Bien cuit", "Sauce à part", "Emballer séparément");
    }
}
