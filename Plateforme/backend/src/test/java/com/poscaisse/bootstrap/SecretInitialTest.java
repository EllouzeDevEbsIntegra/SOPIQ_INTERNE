package com.poscaisse.bootstrap;

import com.poscaisse.BaseDeTest;
import com.poscaisse.repository.UserRepo;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * AUCUN SECRET NE VIENT PLUS DU CODE SOURCE.
 *
 * << admin / admin123 >>, PIN << 9999 >>, etaient ecrits dans DemoDataSeeder : donc
 * identiques sur toutes les installations, publies dans le depot et repris dans la
 * documentation de livraison. Six demonstrations joignables depuis internet s'ouvraient
 * avec cette valeur.
 *
 * CE QUE CE SCENARIO FIGE, et qu'aucun autre ne verrait : que le compte soit cree avec le
 * secret FOURNI, et qu'il n'ait PAS de PIN quand personne n'en a demande un. Le second
 * point compte autant que le premier - quatre chiffres sur le seul compte qui peut tout
 * faire, c'est une porte a dix mille cles, et le ralentisseur ne fait que ralentir.
 *
 * Le refus de demarrer sans secret n'est pas verifiable ici : Spring ne laisse pas
 * observer une application qui refuse de se construire depuis un scenario qui a besoin
 * qu'elle demarre. Il est garanti par la forme du code - une exception au premier
 * amorcage - et par le fait que ce scenario-ci ne passerait pas si la valeur par defaut
 * revenait.
 */
@SpringBootTest(properties = {
        "poscaisse.demo-data=false",
        "poscaisse.admin.password=un-secret-pose-a-l-installation"
})
@EnabledIfEnvironmentVariable(named = "POSCAISSE_IT", matches = "true")
class SecretInitialTest {

    @Autowired UserRepo comptes;
    @Autowired PasswordEncoder encodeur;

    @DynamicPropertySource
    static void baseNeuve(DynamicPropertyRegistry r) { BaseDeTest.neuve(r, "secret_initial"); }

    @Test
    @DisplayName("le compte administrateur porte le secret de l'installation, et aucun autre")
    void leSecretVientDeLInstallation() {
        var admin = comptes.findByUsernameIgnoreCase("admin").orElseThrow();

        assertThat(encodeur.matches("un-secret-pose-a-l-installation", admin.getPasswordHash()))
                .as("le mot de passe est celui fourni").isTrue();
        assertThat(encodeur.matches("admin123", admin.getPasswordHash()))
                .as("l'ancien mot de passe du code source n'ouvre plus rien").isFalse();
    }

    @Test
    @DisplayName("sans PIN demandé, l'administrateur n'en a pas")
    void aucunPinParDefaut() {
        var admin = comptes.findByUsernameIgnoreCase("admin").orElseThrow();
        assertThat(admin.getPinHash()).as("aucun code à quatre chiffres sur le compte tout-puissant").isNull();
    }

    @Test
    @DisplayName("un poste sans démonstration n'a que ce compte-là")
    void aucuneEquipeDeDemonstration() {
        assertThat(comptes.count()).as("ni manager ni caissiers de démonstration").isEqualTo(1);
    }
}
