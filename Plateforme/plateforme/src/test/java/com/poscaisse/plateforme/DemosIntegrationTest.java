package com.poscaisse.plateforme;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.poscaisse.plateforme.domain.Demo;
import com.poscaisse.plateforme.domain.Enums;
import com.poscaisse.plateforme.repository.DemoRepo;
import com.poscaisse.plateforme.service.BasesPostgres;
import com.poscaisse.plateforme.service.DemoService;
import com.poscaisse.plateforme.service.ErreurMetier;
import com.poscaisse.plateforme.service.PosteDemo;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Les six caisses de demonstration : ce qu'on promet a celui qui appuie sur le bouton.
 *
 * Trois promesses, et elles sont couteuses a tenir. Eteindre une demo REND SA BASE NEUVE -
 * pas presque neuve : la table que le prospect a laissee derriere lui n'est plus la, et la
 * base, elle, est toujours debout. Une demo oubliee s'eteint SEULE au bout de vingt-quatre
 * heures, sans que personne l'ait demande. Et la machinerie qui detruit ces bases ne peut
 * pas se tromper de base : elle refuse tout ce qui n'est pas prefixe << posdemo_ >>.
 *
 * Il ne tourne que si PLATEFORME_IT=true et qu'une base PostgreSQL est joignable.
 */
@SpringBootTest
@AutoConfigureMockMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@EnabledIfEnvironmentVariable(named = "PLATEFORME_IT", matches = "true")
class DemosIntegrationTest {

    private static final String HOTE = System.getenv().getOrDefault("PLATEFORME_DB_HOST", "localhost");
    private static final String PORT = System.getenv().getOrDefault("PLATEFORME_DB_PORT", "5432");
    private static final String COMPTE = System.getenv().getOrDefault("PLATEFORME_DB_USER", "postgres");
    private static final String SECRET = System.getenv().getOrDefault("PLATEFORME_DB_PASSWORD", "postgres");

    /*
        SA PROPRE BASE, ET PAS CELLE DE L'AUTRE SCENARIO.

        PlateformeIntegrationTest refait << plateforme_test >> a chaque execution, avec un
        DROP ... WITH (FORCE) qui jette dehors tout ce qui y est connecte. Les deux
        scenarios tournent dans deux contextes Spring differents - les proprietes ne sont
        pas les memes - et les deux gardent un pool ouvert le temps de la suite : partager
        le nom de la base, c'est laisser l'un couper les connexions de l'autre au moment ou
        JUnit lance le second. On prend donc un nom a nous.
    */
    private static final String BASE_DU_TEST = "plateforme_test_demos";

    /** Celle qu'on allume et qu'on eteint pour de vrai. Sa base sera creee, puis rendue neuve. */
    private static final String BASE_DEMO_CAFE = "posdemo_cafe";

    @DynamicPropertySource
    static void baseNeuve(DynamicPropertyRegistry r) {
        surPostgres("DROP DATABASE IF EXISTS " + BASE_DU_TEST + " WITH (FORCE)");
        surPostgres("CREATE DATABASE " + BASE_DU_TEST);
        r.add("spring.datasource.url", () -> "jdbc:postgresql://" + HOTE + ":" + PORT + "/" + BASE_DU_TEST);
        r.add("spring.datasource.username", () -> COMPTE);
        r.add("spring.datasource.password", () -> SECRET);
        // Ce nom n'est pas << systemd >> : le lanceur reel ne se charge donc pas, et c'est
        // le poste factice ci-dessous qui prend sa place.
        r.add("plateforme.demo.lanceur", () -> "factice");
        /*
            L'HORLOGE EST MISE AU LARGE, PAS DEBRANCHEE. Elle passe une premiere fois au
            demarrage du contexte - a ce moment aucune demo n'est allumee, elle ne fait
            rien - puis plus avant une heure. Sans cela, sa passe suivante tomberait au
            milieu du test des vingt-quatre heures et eteindrait la demo que le test
            s'apprete a compter lui-meme.
        */
        r.add("plateforme.demo.verification", () -> "PT1H");
    }

    /**
     * Un poste qui note ce qu'on lui demande et ne lance rien.
     *
     * Le vrai lanceur appelle sudo sur un script du serveur : un test qui passerait par la
     * exigerait une machine equipee, donc ne tournerait nulle part. Tout le reste - la
     * base creee, la base rendue neuve, l'expiration, les droits - s'execute pour de vrai.
     */
    static class PosteFactice implements PosteDemo {
        final List<String> appels = new ArrayList<>();
        boolean allume;

        @Override public void demarrer(Demo d) { appels.add("demarrer:" + d.getModule()); allume = true; }
        @Override public void arreter(Demo d) { appels.add("arreter:" + d.getModule()); allume = false; }
        @Override public boolean tourne(Demo d) { return allume; }
    }

    @TestConfiguration
    static class LanceurDeTest {
        @Bean PosteDemo posteDemo() { return new PosteFactice(); }
    }

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper om;
    @Autowired PosteDemo poste;
    @Autowired DemoRepo demos;
    @Autowired DemoService service;
    @Autowired BasesPostgres bases;

    static String jeton;

    // ------------------------------------------------------------------ les scenarios

    /**
     * Ce que ce test protege : qu'appuyer sur << Démarrer >> prepare vraiment la caisse.
     *
     * Une ligne passee a << allumee = true >> ne montre rien a un prospect. Il faut que la
     * base existe sur le serveur, que le processus ait ete lance, et que l'ecran puisse
     * afficher l'adresse a envoyer - sans quoi le commercial promet un rendez-vous devant
     * une page qui ne repond pas.
     */
    @Test @Order(1) void demarrerUneDemoCreeSaBaseEtLAllume() throws Exception {
        connexion("admin", "plateforme123");

        JsonNode toutes = lire("/api/demos");
        assertThat(toutes).as("les six métiers, toujours là").hasSize(6);
        assertThat(toutes.get(0).get("allumee").asBoolean()).isFalse();

        JsonNode d = json(poster("/api/demos/CAFE/demarrer", Map.of(), 200));
        assertThat(d.get("allumee").asBoolean()).isTrue();
        assertThat(d.get("metier").asText()).isEqualTo("Café");
        // L'adresse est complete : c'est elle qu'on colle dans un courriel au prospect.
        assertThat(d.get("url").asText()).isEqualTo("https://demo-cafe.pos.ebs-integra.com");
        assertThat(d.get("demarreePar").asText()).isEqualTo("admin");
        assertThat(d.get("resteMinutes").asLong()).isBetween(23L * 60, 24L * 60);

        assertThat(((PosteFactice) poste).appels).contains("demarrer:CAFE");
        assertThat(existe(BASE_DEMO_CAFE)).as("la base de la démo est créée pour de vrai").isTrue();
    }

    /**
     * Ce que ce test protege : la promesse faite au commercial dans la fenetre de
     * confirmation - << la base sera remise à son état de démonstration initial >>.
     *
     * C'est le seul geste du back-office qui detruit des donnees. S'il se contentait
     * d'arreter le processus, la demonstration suivante s'ouvrirait sur les trois articles
     * bricoles par le prospect precedent, ses prix a lui et ses ventes d'essai. Et s'il
     * detruisait un peu trop - la base elle-meme, son role - la demo suivante ne
     * demarrerait plus du tout.
     *
     * On pose donc un temoin dans la base avant d'eteindre, et on verifie les deux choses :
     * le temoin a disparu, la base est toujours debout.
     */
    @Test @Order(2) void arreterRemetLaBaseANeuf() throws Exception {
        dansLaDemo("CREATE TABLE temoin_du_prospect (id int)");
        assertThat(temoinPresent()).as("le témoin est bien posé avant l'arrêt").isTrue();

        JsonNode d = json(poster("/api/demos/CAFE/arreter", Map.of(), 200));
        assertThat(d.get("allumee").asBoolean()).isFalse();
        assertThat(((PosteFactice) poste).appels).contains("arreter:CAFE");

        assertThat(existe(BASE_DEMO_CAFE)).as("la base existe toujours : elle a été refaite, pas supprimée").isTrue();
        assertThat(temoinPresent()).as("ce que le prospect a saisi a disparu").isFalse();

        // Et l'ecran le voit : plus d'heure de demarrage, plus de compte a rebours.
        JsonNode apres = laDemo(lire("/api/demos"), "CAFE");
        assertThat(apres.get("allumee").asBoolean()).isFalse();
        assertThat(apres.has("resteMinutes")).isFalse();
    }

    /**
     * Ce que ce test protege : qu'une demo oubliee un vendredi soir ne tourne pas jusqu'au
     * lundi.
     *
     * Personne n'appelle cette regle - c'est l'horloge, qui n'est connectee sous aucun
     * compte. Elle doit donc s'appliquer sans qu'on lui donne de droit, et surtout elle ne
     * doit pas emporter au passage la demo qu'un commercial est en train de montrer :
     * arreter le rendez-vous de quelqu'un pour faire de la place serait pire que le
     * probleme qu'on resout.
     */
    @Test @Order(3) void laRegleDesVingtQuatreHeures() {
        Demo oubliee = demos.findById(Enums.Module.RESTO).orElseThrow();
        oubliee.setAllumee(true);
        oubliee.setDemarreeLe(OffsetDateTime.now().minusHours(25));
        oubliee.setDemarreePar("commercial");
        demos.save(oubliee);

        Demo enCours = demos.findById(Enums.Module.SHOP).orElseThrow();
        enCours.setAllumee(true);
        enCours.setDemarreeLe(OffsetDateTime.now().minusHours(1));
        demos.save(enCours);

        assertThat(service.arreterLesExpirees()).isEqualTo(1);

        assertThat(demos.findById(Enums.Module.RESTO).orElseThrow().isAllumee())
                .as("celle de vendredi soir est éteinte").isFalse();
        assertThat(demos.findById(Enums.Module.SHOP).orElseThrow().isAllumee())
                .as("le rendez-vous en cours n'est pas interrompu").isTrue();

        // Rien a nettoyer sur le disque : ces deux-la n'ont jamais eu de base sur ce serveur.
        assertThat(existe("posdemo_resto")).isFalse();
    }

    /**
     * Ce que ce test protege : la base d'un client qui paie.
     *
     * {@code remettreANeuf} fait un DROP DATABASE. C'est le seul endroit du logiciel qui
     * supprime une base, et rien ne separe visuellement << posdemo_cafe >> de
     * << pos_cli0001_cafe >> dans un appel mal ecrit. Le prefixe est la frontiere, et le
     * refus doit NOMMER ce prefixe : celui qui lit l'erreur doit comprendre en une ligne
     * qu'il vient de viser une base de client, et non chercher pourquoi << ça ne marche
     * pas >>.
     */
    @Test @Order(4) void leGardeFouRefuseLaBaseDUnClient() {
        assertThatThrownBy(() -> bases.remettreANeuf("pos_cli0001_cafe", "pos_cli0001_cafe"))
                .isInstanceOf(ErreurMetier.class)
                .hasMessageContaining("pos_cli0001_cafe")
                .hasMessageContaining(BasesPostgres.PREFIXE_DEMO);

        // Et il n'a rien touche en chemin.
        assertThat(existe(BASE_DEMO_CAFE)).isTrue();
    }

    /**
     * Ce que ce test protege : qu'un compte qui regarde ne puisse pas effacer.
     *
     * SUPPORT lit les dossiers pour repondre au telephone. Demarrer une demo cree une base
     * sur le serveur, et l'arreter en detruit une : ces deux gestes appartiennent a ceux
     * qui gerent les clients. Le refus doit dire quel role manque, sinon celui qui le lit
     * ne sait pas a qui demander.
     */
    @Test @Order(5) void unSupportNePeutPasDemarrerUneDemo() throws Exception {
        connexion("admin", "plateforme123");
        poster("/api/utilisateurs", Map.of("username", "support-demos", "fullName", "Support",
                "password", "support12345", "role", "SUPPORT"), 200);
        connexion("support-demos", "support12345");

        lire("/api/demos");   // regarder l'etat des demos : autorise
        MvcResult refus = poster("/api/demos/PARFUMERIE/demarrer", Map.of(), 403);
        assertThat(refus.getResponse().getContentAsString()).contains("SUPPORT").contains("administrateur");
        assertThat(demos.findById(Enums.Module.PARFUMERIE).orElseThrow().isAllumee()).isFalse();

        assertThat(poster("/api/demos/CAFE/arreter", Map.of(), 403)
                .getResponse().getContentAsString()).contains("SUPPORT");
    }

    /**
     * On range derriere le test.
     *
     * La base de demonstration et son role restent sinon sur la machine du developpeur
     * apres chaque execution. Le scenario est rejouable dans les deux cas - demarrer ne
     * recree pas une base qui existe - mais on ne laisse pas trainer ce qu'on a cree.
     */
    @AfterAll
    static void ranger() {
        surPostgres("DROP DATABASE IF EXISTS " + BASE_DEMO_CAFE + " WITH (FORCE)");
        surPostgres("DROP USER IF EXISTS " + BASE_DEMO_CAFE);
    }

    // ------------------------------------------------------------------ mecanique

    private static void surPostgres(String sql) {
        try (java.sql.Connection cx = java.sql.DriverManager.getConnection(
                     "jdbc:postgresql://" + HOTE + ":" + PORT + "/postgres", COMPTE, SECRET);
             java.sql.Statement st = cx.createStatement()) {
            st.executeUpdate(sql);
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException("« " + sql + " » a échoué : " + e.getMessage(), e);
        }
    }

    private static boolean existe(String base) {
        try (java.sql.Connection cx = java.sql.DriverManager.getConnection(
                     "jdbc:postgresql://" + HOTE + ":" + PORT + "/postgres", COMPTE, SECRET);
             java.sql.Statement st = cx.createStatement();
             java.sql.ResultSet rs = st.executeQuery("SELECT 1 FROM pg_database WHERE datname = '" + base + "'")) {
            return rs.next();
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** Une instruction jouee DANS la base de la demo, comme le ferait la caisse elle-meme. */
    private static void dansLaDemo(String sql) {
        try (java.sql.Connection cx = java.sql.DriverManager.getConnection(
                     "jdbc:postgresql://" + HOTE + ":" + PORT + "/" + BASE_DEMO_CAFE, COMPTE, SECRET);
             java.sql.Statement st = cx.createStatement()) {
            st.executeUpdate(sql);
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException("« " + sql + " » a échoué : " + e.getMessage(), e);
        }
    }

    private static boolean temoinPresent() {
        try (java.sql.Connection cx = java.sql.DriverManager.getConnection(
                     "jdbc:postgresql://" + HOTE + ":" + PORT + "/" + BASE_DEMO_CAFE, COMPTE, SECRET);
             java.sql.Statement st = cx.createStatement();
             java.sql.ResultSet rs = st.executeQuery("SELECT to_regclass('public.temoin_du_prospect') IS NOT NULL")) {
            return rs.next() && rs.getBoolean(1);
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private JsonNode json(MvcResult r) throws Exception { return om.readTree(r.getResponse().getContentAsString()); }

    /** La ligne d'un metier dans la liste, sans supposer l'ordre dans lequel elle arrive. */
    private static JsonNode laDemo(JsonNode liste, String module) {
        for (JsonNode d : liste) if (module.equals(d.get("module").asText())) return d;
        throw new AssertionError("La démo « " + module + " » n'est pas dans la liste.");
    }

    private void connexion(String qui, String motDePasse) throws Exception {
        jeton = null;
        jeton = json(poster("/api/auth/connexion", Map.of("username", qui, "password", motDePasse), 200))
                .get("token").asText();
    }

    /** Poster, avec le jeton courant. Nommee en francais pour ne pas masquer MockMvc.post. */
    private MvcResult poster(String url, Object corps, int statut) throws Exception {
        var req = post(url).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(corps));
        if (jeton != null) req = req.header("Authorization", "Bearer " + jeton);
        return mvc.perform(req).andExpect(status().is(statut)).andReturn();
    }

    private JsonNode lire(String url) throws Exception {
        return json(mvc.perform(get(url).header("Authorization", "Bearer " + jeton))
                .andExpect(status().isOk()).andReturn());
    }
}
