package com.poscaisse.bootstrap;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.poscaisse.dto.CatalogImportDtos.CatalogImport;
import com.poscaisse.dto.CatalogImportDtos.ImportProduct;
import com.poscaisse.service.SettingsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.core.io.ClassPathResource;

import java.io.InputStream;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Ce que chaque metier promet, verifie sans base de donnees.
 *
 * POURQUOI CE TEST EXISTE. Un profil est une ligne de declarations : un nom de fichier, des
 * noms de reglages, des valeurs. Rien dans le compilateur ne dit qu'un fichier existe ni
 * qu'un reglage est connu. Une faute de frappe dans << mistral-coffee.json >> ne se
 * verrait qu'au premier demarrage chez un client, sur une caisse vide, un matin
 * d'ouverture - et le journal serait le seul a le savoir.
 *
 * Il est volontairement sans Spring : il tourne en une fraction de seconde, a chaque
 * compilation, y compris sur une machine sans PostgreSQL.
 */
class ProfilMetierTest {

    private static final ObjectMapper OM = new ObjectMapper();

    /** Les reglages qu'un profil a le droit de poser : ceux que la caisse sait relire. */
    private static final Set<String> CONNUS = SettingsService.defaults().keySet();

    @ParameterizedTest @EnumSource(ProfilMetier.class)
    void chaqueProfilSeDecritEntierement(ProfilMetier p) {
        assertThat(p.libelle()).as("libellé de " + p).isNotBlank();
        assertThat(p.enseigne()).as("enseigne de démonstration de " + p).isNotBlank();
        assertThat(p.reglages()).as("réglages de " + p).isNotEmpty();
    }

    /**
     * Un reglage inconnu serait ecrit en base et ne servirait jamais : il n'apparaitrait
     * sur aucun ecran, et personne ne comprendrait pourquoi le metier ne se comporte pas
     * comme annonce.
     */
    @ParameterizedTest @EnumSource(ProfilMetier.class)
    void lesReglagesDUnProfilSontDesReglagesQueLaCaisseConnait(ProfilMetier p) {
        for (Map.Entry<String, String> e : p.reglages().entrySet()) {
            assertThat(CONNUS).as("réglage « %s » posé par %s", e.getKey(), p).contains(e.getKey());
            assertThat(e.getValue()).as("valeur de « %s » pour %s", e.getKey(), p).isNotNull();
        }
    }

    /** Le mode de service par defaut doit faire partie des modes ouverts, sinon la caisse ouvre sur rien. */
    @ParameterizedTest @EnumSource(ProfilMetier.class)
    void leModeParDefautEstUnModeOuvert(ProfilMetier p) {
        String modes = p.reglages().get(SettingsService.SERVICE_MODES);
        String defaut = p.reglages().get(SettingsService.DEFAULT_SERVICE_MODE);
        assertThat(modes.split(",")).as("modes de %s", p).contains(defaut);
    }

    /**
     * La carte annoncee existe dans le JAR, se lit, et contient des articles.
     *
     * C'est le test qui vaut le plus cher : il transforme une caisse vide chez un client
     * en echec de compilation chez nous.
     */
    @ParameterizedTest @EnumSource(ProfilMetier.class)
    void laCarteAnnonceeExisteEtSeCharge(ProfilMetier p) throws Exception {
        if (p.carte() == null) return;   // RESTO : sa carte est ecrite dans le code, avec ses menus
        ClassPathResource r = new ClassPathResource("cartes/" + p.carte());
        assertThat(r.exists()).as("cartes/%s absente du JAR pour %s", p.carte(), p).isTrue();
        try (InputStream flux = r.getInputStream()) {
            CatalogImport carte = OM.readValue(flux, CatalogImport.class);
            assertThat(carte.products()).as("articles de %s", p.carte()).isNotEmpty();
            assertThat(carte.categories()).as("catégories de %s", p.carte()).isNotEmpty();
            for (ImportProduct a : carte.products()) {
                assertThat(a.code()).as("code d'article dans %s", p.carte()).isNotBlank();
                assertThat(a.price()).as("prix de « %s » dans %s", a.name(), p.carte()).isNotNull();
                // Une unite mal orthographiee laisserait l'article a la piece sans que
                // personne le voie : « Baklawa 58,000 » se vendrait alors aux 58 dinars.
                if (a.unite() != null && !a.unite().isBlank())
                    assertThat(com.poscaisse.domain.Enums.Unite.valueOf(a.unite()))
                            .as("unité de « %s » dans %s", a.name(), p.carte()).isNotNull();
            }
        }
    }

    /**
     * Un metier qui scanne doit avoir des codes-barres dans sa carte, et l'inverse.
     *
     * Le contraire donne une demonstration qui ment : une superette livree sans un seul
     * code a scanner, ou un cafe dont les fiches montrent un champ code-barres vide sur
     * chaque cafe express.
     */
    @ParameterizedTest @EnumSource(ProfilMetier.class)
    void leScanEtLaCarteDisentLaMemeChose(ProfilMetier p) throws Exception {
        if (p.carte() == null) return;
        boolean scanne = "true".equals(p.reglages().get(SettingsService.BARCODE_ENABLED));
        if (!scanne) return;   // une carte peut porter des codes sans qu'on les utilise
        try (InputStream flux = new ClassPathResource("cartes/" + p.carte()).getInputStream()) {
            CatalogImport carte = OM.readValue(flux, CatalogImport.class);
            long avecCode = carte.products().stream().filter(a -> a.barcode() != null && !a.barcode().isBlank()).count();
            assertThat(avecCode).as("%s scanne mais sa carte n'a aucun code-barres", p).isPositive();
        }
    }

    @Test
    void leNomDUnProfilSeLitDansNimporteQuelleCasse() {
        assertThat(ProfilMetier.parNom("cafe")).isEqualTo(ProfilMetier.CAFE);
        assertThat(ProfilMetier.parNom("  Shop ")).isEqualTo(ProfilMetier.SHOP);
        assertThat(ProfilMetier.parNom("boulangerie")).as("un métier inconnu ne devine pas").isNull();
        assertThat(ProfilMetier.parNom("")).isNull();
        assertThat(ProfilMetier.parNom(null)).isNull();
    }

    /**
     * La patisserie vend au poids, et sa carte doit le dire.
     *
     * C'est le coeur du metier : de la baklawa a 58 dinars le kilo dont on vend 300
     * grammes. Une carte regeneree sans les unites livrerait une patisserie qui ne sait
     * vendre qu'au kilo entier - le vendeur recalculerait de tete a chaque client, et
     * personne ne verrait d'ou vient la perte.
     */
    @Test
    void laPatisserieVendAuPoids() throws Exception {
        try (InputStream flux = new ClassPathResource("cartes/" + ProfilMetier.PATISSERIE.carte()).getInputStream()) {
            CatalogImport carte = OM.readValue(flux, CatalogImport.class);
            long auKilo = carte.products().stream().filter(a -> "KG".equals(a.unite())).count();
            assertThat(auKilo).as("articles vendus au kilo dans la carte pâtisserie").isGreaterThanOrEqualTo(15);
            // Et le nom ne repete pas l'unite : « Baklawa amande (kg) 0,300 kg » sur un
            // ticket se lit deux fois, et mal.
            assertThat(carte.products().stream().filter(a -> "KG".equals(a.unite())))
                    .allSatisfy(a -> assertThat(a.name()).doesNotContain("(kg)"));
        }
    }
}
