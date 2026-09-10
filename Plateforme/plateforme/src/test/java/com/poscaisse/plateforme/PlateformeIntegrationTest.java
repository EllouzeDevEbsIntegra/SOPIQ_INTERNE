package com.poscaisse.plateforme;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le parcours complet d'un client de la plateforme, du prospect a l'impaye.
 *
 * Ce que ce scenario protege, ce n'est pas une methode : c'est la promesse commerciale.
 * Souscrire donne une licence ; la licence ouvre le nombre de caisses vendu et pas une de
 * plus ; une facture impayee suspend le service SANS effacer quoi que ce soit ; et la
 * caisse suspendue le dit en francais a celui qui la regarde.
 *
 * Il ne tourne que si PLATEFORME_IT=true et qu'une base PostgreSQL est joignable.
 */
@SpringBootTest(properties = "plateforme.admin-password=plateforme123")
@AutoConfigureMockMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@EnabledIfEnvironmentVariable(named = "PLATEFORME_IT", matches = "true")
class PlateformeIntegrationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper om;
    @Autowired javax.sql.DataSource source;

    /*
        LE SCENARIO TRAVAILLE SUR SA BASE, PAS SUR CELLE DE LA DEMONSTRATION.

        Il cree des clients, emet des factures, encaisse. Lance sur la base « plateforme »,
        il ajoutait ses clients a ceux qu'on y regarde, et l'inverse etait vrai : le
        chiffre du tableau de bord montait avec chaque demonstration faite au navigateur,
        et l'assertion qui l'attendait a 49 dinars finissait par tomber sur 207. Le test
        n'etait pas faux ; il lisait le desordre de quelqu'un d'autre.

        Donc : une base a lui, refaite a neuf a chaque execution. Flyway y pose le schema,
        l'amorcage y cree le premier compte, et ce que le scenario compte est ce que le
        scenario a fait.
    */
    private static final String HOTE = System.getenv().getOrDefault("PLATEFORME_DB_HOST", "localhost");
    private static final String PORT = System.getenv().getOrDefault("PLATEFORME_DB_PORT", "5432");
    private static final String COMPTE = System.getenv().getOrDefault("PLATEFORME_DB_USER", "postgres");
    private static final String SECRET = System.getenv().getOrDefault("PLATEFORME_DB_PASSWORD", "postgres");
    private static final String BASE_DU_TEST = "plateforme_test";

    @DynamicPropertySource
    static void baseNeuve(DynamicPropertyRegistry r) {
        String administration = "jdbc:postgresql://" + HOTE + ":" + PORT + "/postgres";
        try (java.sql.Connection cx = java.sql.DriverManager.getConnection(administration, COMPTE, SECRET);
             java.sql.Statement st = cx.createStatement()) {
            // FORCE : une execution precedente interrompue laisse parfois une connexion
            // ouverte, et la suppression attendrait indefiniment.
            st.executeUpdate("DROP DATABASE IF EXISTS " + BASE_DU_TEST + " WITH (FORCE)");
            st.executeUpdate("CREATE DATABASE " + BASE_DU_TEST);
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException("Base de test impossible a preparer : " + e.getMessage(), e);
        }
        r.add("spring.datasource.url", () -> "jdbc:postgresql://" + HOTE + ":" + PORT + "/" + BASE_DU_TEST);
        r.add("spring.datasource.username", () -> COMPTE);
        r.add("spring.datasource.password", () -> SECRET);
    }

    static String jeton;
    static long clientId;
    static long abonnementId;
    static String cleLicence;
    static long factureId;

    private JsonNode json(MvcResult r) throws Exception { return om.readTree(r.getResponse().getContentAsString()); }

    private int numeroDe(JsonNode facture) {
        String n = facture.get("numero").asText();
        return Integer.parseInt(n.substring(n.lastIndexOf('-') + 1));
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

    @Test @Order(1) void connexionEtPremierCompte() throws Exception {
        JsonNode r = json(poster("/api/auth/connexion",
                Map.of("username", "admin", "password", "plateforme123"), 200));
        jeton = r.get("token").asText();
        assertThat(jeton).isNotBlank();
        assertThat(r.get("utilisateur").get("role").asText()).isEqualTo("ADMIN");
        // La session du back-office est courte : il voit tous les clients.
        assertThat(r.get("expireDansMinutes").asLong()).isLessThanOrEqualTo(240);
    }

    @Test @Order(2) void mauvaisMotDePasseRalenti() throws Exception {
        int refus = 0, ralentis = 0;
        for (int i = 0; i < 8; i++) {
            MvcResult r = mvc.perform(post("/api/auth/connexion").header("X-Forwarded-For", "203.0.113.55")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"username\":\"admin\",\"password\":\"faux\"}")).andReturn();
            if (r.getResponse().getStatus() == 401) refus++;
            if (r.getResponse().getStatus() == 429) ralentis++;
        }
        assertThat(refus).isGreaterThanOrEqualTo(3);
        assertThat(ralentis).as("la porte se ferme le temps qu'il faut").isPositive();
    }

    @Test @Order(3) void creerUnClientEtSouscrire() throws Exception {
        JsonNode c = json(poster("/api/clients", Map.of(
                "raisonSociale", "SARL Chez Ahmed", "enseigne", "Café Mistral",
                "contactNom", "Ahmed Ben Salah", "contactTel", "98 000 000", "ville", "Sfax"), 200));
        clientId = c.get("id").asLong();
        assertThat(c.get("code").asText()).matches("CLI-\\d{4}");
        assertThat(c.get("statut").asText()).as("un client neuf est un prospect").isEqualTo("PROSPECT");

        JsonNode a = json(poster("/api/clients/" + clientId + "/abonnements", Map.of(
                "module", "CAFE", "formule", "MENSUEL", "nbCaisses", 1,
                "prixMensuel", 49, "debutLe", LocalDate.now().toString()), 200));
        abonnementId = a.get("id").asLong();
        assertThat(a.get("licences")).as("souscrire donne une licence").isNotEmpty();
        cleLicence = a.get("licences").get(0).get("cle").asText();
        assertThat(cleLicence).matches("[A-Z2-9]{5}(-[A-Z2-9]{5}){3}");

        // Le statut suit les faits : personne n'a a penser a le changer.
        assertThat(lire("/api/clients/" + clientId).get("statut").asText()).isEqualTo("ACTIF");
    }

    @Test @Order(4) void laLicenceOuvreLeNombreDeCaissesVendu() throws Exception {
        JsonNode ok = json(poster("/api/licences/verifier",
                Map.of("cle", cleLicence, "empreinte", "POSTE-A", "libelle", "Caisse comptoir"), 200));
        assertThat(ok.get("autorise").asBoolean()).isTrue();
        assertThat(ok.get("module").asText()).isEqualTo("CAFE");

        // Le meme poste peut se representer autant qu'il veut : il ne consomme qu'une place.
        assertThat(json(poster("/api/licences/verifier",
                Map.of("cle", cleLicence, "empreinte", "POSTE-A"), 200)).get("autorise").asBoolean()).isTrue();

        // Une seconde caisse, alors qu'une seule est vendue : refus, avec la phrase qui dit quoi faire.
        JsonNode trop = json(poster("/api/licences/verifier",
                Map.of("cle", cleLicence, "empreinte", "POSTE-B"), 200));
        assertThat(trop.get("autorise").asBoolean()).isFalse();
        assertThat(trop.get("message").asText()).contains("1 caisse").contains("fournisseur");

        // Une cle inconnue ne dit pas si le client existe : elle dit de verifier la saisie.
        assertThat(json(poster("/api/licences/verifier", Map.of("cle", "AAAAA-BBBBB-CCCCC-DDDDD"), 200))
                .get("autorise").asBoolean()).isFalse();
    }

    @Test @Order(5) void facturerEtEncaisser() throws Exception {
        JsonNode f = json(poster("/api/abonnements/" + abonnementId + "/factures", Map.of(
                "periodeDebut", LocalDate.now().withDayOfMonth(1).toString(),
                "periodeFin", LocalDate.now().withDayOfMonth(1).plusMonths(1).minusDays(1).toString()), 200));
        factureId = f.get("id").asLong();
        assertThat(f.get("numero").asText()).matches("FAC-\\d{4}-\\d{4}");
        /*
            Le numero suivant, et non le meme : le compteur se lisait a partir du mauvais
            caractere et ramenait << -0001 >>, converti en -1. La deuxieme facture de
            l'annee s'appelait alors 0000, et la troisieme aussi.
        */
        JsonNode f2 = json(poster("/api/abonnements/" + abonnementId + "/factures", Map.of(
                "periodeDebut", LocalDate.now().plusMonths(1).withDayOfMonth(1).toString(),
                "periodeFin", LocalDate.now().plusMonths(1).withDayOfMonth(28).toString()), 200));
        assertThat(f2.get("numero").asText()).isNotEqualTo(f.get("numero").asText());
        assertThat(numeroDe(f2)).as("la suite, pas un retour a zero").isEqualTo(numeroDe(f) + 1);
        poster("/api/factures/" + f2.get("id").asLong() + "/annuler", Map.of("motif", "test"), 200);
        assertThat(f.get("montant").decimalValue()).isEqualByComparingTo("49.000");
        assertThat(f.get("reste").decimalValue()).isEqualByComparingTo("49.000");

        // Un reglement partiel : la facture reste emise, le reste se deduit.
        JsonNode partiel = json(poster("/api/factures/" + factureId + "/reglements",
                Map.of("montant", 20, "moyen", "VIREMENT", "reference", "VIR-77"), 200));
        assertThat(partiel.get("statut").asText()).isEqualTo("EMISE");
        assertThat(partiel.get("reste").decimalValue()).isEqualByComparingTo("29.000");

        // On n'encaisse pas plus que le reste du : un trop-percu se regle en parlant.
        MvcResult trop = poster("/api/factures/" + factureId + "/reglements", Map.of("montant", 100), 400);
        assertThat(trop.getResponse().getContentAsString()).contains("dépasse le reste dû");

        JsonNode solde = json(poster("/api/factures/" + factureId + "/reglements",
                Map.of("montant", 29, "moyen", "ESPECES"), 200));
        assertThat(solde.get("statut").asText()).as("soldee, elle passe payee toute seule").isEqualTo("PAYEE");
        assertThat(solde.get("reste").decimalValue()).isEqualByComparingTo("0.000");
    }

    @Test @Order(9) void impayeSuspensionEtRetablissement() throws Exception {
        // Une facture echue depuis longtemps : c'est le cas qu'on veut voir arriver.
        JsonNode vieille = json(poster("/api/abonnements/" + abonnementId + "/factures", Map.of(
                "periodeDebut", LocalDate.now().minusMonths(3).withDayOfMonth(1).toString(),
                "periodeFin", LocalDate.now().minusMonths(3).withDayOfMonth(28).toString(),
                "emiseLe", LocalDate.now().minusDays(90).toString(),
                "echeanceLe", LocalDate.now().minusDays(60).toString()), 200));
        assertThat(vieille.get("enRetard").asBoolean()).isTrue();

        assertThat(lire("/api/factures/en-retard")).isNotEmpty();

        List<String> suspendus = om.convertValue(
                json(poster("/api/factures/suspendre-les-retards", Map.of(), 200)), List.class);
        assertThat(suspendus).isNotEmpty();
        assertThat(lire("/api/clients/" + clientId).get("statut").asText()).isEqualTo("SUSPENDU");

        /*
            Le point le plus important du fichier : suspendu n'est pas coupe. La caisse
            passe en LECTURE SEULE et le dit en francais. Les donnees du commercant sont a
            lui - un impaye de quarante dinars ne les lui prend pas.
        */
        JsonNode verif = json(poster("/api/licences/verifier",
                Map.of("cle", cleLicence, "empreinte", "POSTE-A"), 200));
        assertThat(verif.get("autorise").asBoolean()).isFalse();
        assertThat(verif.get("lectureSeule").asBoolean()).isTrue();
        assertThat(verif.get("message").asText()).contains("lecture seule").contains("intactes");

        // Reglement recu : on retablit, et la caisse rouvre.
        long id = vieille.get("id").asLong();
        poster("/api/factures/" + id + "/reglements", Map.of("montant", vieille.get("reste").decimalValue()), 200);
        poster("/api/clients/" + clientId + "/reactiver", Map.of(), 200);
        assertThat(json(poster("/api/licences/verifier", Map.of("cle", cleLicence, "empreinte", "POSTE-A"), 200))
                .get("autorise").asBoolean()).isTrue();
    }

    /**
     * Preparer la base d'un client, depuis le back-office.
     *
     * Ce que ce test protege : qu'on ne rende jamais un mot de passe deux fois, et qu'un
     * provisionnement relance par megarde sur un client en service ne casse rien.
     */
    @Test @Order(6) void provisionnerLaBaseDUnClient() throws Exception {
        JsonNode r = json(poster("/api/abonnements/" + abonnementId + "/provisionner",
                Map.of("demonstration", true), 200));
        String base = r.get("base").asText();
        assertThat(base).matches("[a-z0-9_]+").contains("cafe");
        assertThat(r.get("motDePasse").asText()).as("rendu une seule fois").isNotBlank();
        assertThat(r.get("carteDeDemonstration").asText()).isEqualTo("mistral-coffee.json");

        /*
            LA COMMANDE DOIT SUFFIRE. Elle remplace la visite d'un technicien : si elle
            oublie le profil, la caisse s'ouvre en fast-food chez un cafetier ; si elle
            oublie la langue, l'enseigne accentuee arrive abimee et s'imprime ainsi sur
            chaque ticket. On verifie donc la ligne entiere, pas seulement la base.
        */
        String commande = r.get("commande").asText();
        assertThat(commande)
                .contains("POSCAISSE_DB_NAME=" + base)
                .contains("POSCAISSE_PROFIL=CAFE")
                .contains("POSCAISSE_DEMO_DATA=true")
                .contains("LANG=C.UTF-8")
                .contains("POSCAISSE_ENSEIGNE=");

        /*
            L'ADRESSE, ET LE PORT QUI LA REND POSSIBLE.

            Le provisionnement preparait la base et s'arretait la : le client n'avait aucune
            adresse a taper le matin, et la commande ne portait aucun port - deux caisses
            ouvertes le meme jour se seraient battues pour le 8080, la seconde echouant sur
            un << Address already in use >> dans un journal que personne ne lit.
        */
        String sousDomaine = r.get("sousDomaine").asText();
        assertThat(sousDomaine).as("lisible au téléphone").matches("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$");
        assertThat(r.get("adresse").asText()).isEqualTo("https://" + sousDomaine + ".pos.ebs-integra.com");
        int portCaisse = r.get("portCaisse").asInt();
        assertThat(portCaisse).isBetween(8101, 8120);
        assertThat(commande).contains("POSCAISSE_PORT=" + portCaisse);

        /*
            LA COMMANDE D'OUVERTURE NE PORTE PAS LE MOT DE PASSE, et ce test est la pour
            que personne ne l'y remette par commodite : tout ce qui passe en argument se
            lit dans << ps >> par n'importe quel compte de la machine, et reste dans
            l'historique du shell. Le script le demande a l'ecran.
        */
        String ouverture = r.get("ouverture").asText();
        assertThat(ouverture)
                .contains("poscaisse-ouvrir")
                .contains("--sous-domaine " + sousDomaine)
                .contains("--port " + portCaisse)
                .contains("--profil CAFE")
                .doesNotContain(r.get("motDePasse").asText());

        // La base existe vraiment - ce n'est pas une ligne dans une table.
        try (java.sql.Connection cx = source.getConnection();
             java.sql.Statement st = cx.createStatement();
             java.sql.ResultSet rs = st.executeQuery("select 1 from pg_database where datname = '" + base + "'")) {
            assertThat(rs.next()).as("la base est créée").isTrue();
        }

        /*
            LE CLOISONNEMENT, VERIFIE ET NON SUPPOSE.

            PostgreSQL accorde CONNECT a PUBLIC sur toute base neuve : sans ce retrait, le
            compte d'un client ouvrait la base d'un autre. Il n'y lisait pas de donnees,
            mais il y lisait le nom de toutes les bases - donc de tous nos clients.
        */
        try (java.sql.Connection cx = source.getConnection();
             java.sql.Statement st = cx.createStatement();
             java.sql.ResultSet rs = st.executeQuery(
                     "select has_database_privilege('public', '" + base + "', 'CONNECT'),"
                   + "       has_database_privilege('" + base + "', '" + base + "', 'CONNECT')")) {
            assertThat(rs.next()).isTrue();
            assertThat(rs.getBoolean(1)).as("plus personne d'autre ne peut ouvrir cette base").isFalse();
            assertThat(rs.getBoolean(2)).as("son propriétaire, lui, l'ouvre").isTrue();
        }

        // Relance : on ne recree rien, on ne rend pas de nouveau mot de passe.
        JsonNode encore = json(poster("/api/abonnements/" + abonnementId + "/provisionner", Map.of(), 200));
        assertThat(encore.get("message").asText()).contains("existait déjà");
        assertThat(encore.has("motDePasse")).as("aucun mot de passe rendu deux fois").isFalse();

        // L'adresse est ECRITE SUR LE COMPTOIR du client : elle ne bouge pas parce qu'on a
        // recliqué sur un bouton.
        assertThat(encore.get("sousDomaine").asText()).as("l'adresse ne change jamais").isEqualTo(sousDomaine);
        assertThat(encore.get("portCaisse").asInt()).as("le port non plus").isEqualTo(portCaisse);

        /*
            << REPARTIR DE ZERO >>. Le commercial change d'avis : ce client a deja son
            catalogue et ne veut pas effacer 112 articles de demonstration avant de
            commencer. Le choix se refait sur une base deja creee - il ne touche pas a la
            base, il change la commande qu'on remet au client.
        */
        JsonNode vide = json(poster("/api/abonnements/" + abonnementId + "/provisionner",
                Map.of("demonstration", false), 200));
        assertThat(vide.get("commande").asText()).contains("POSCAISSE_DEMO_DATA=false");
        assertThat(vide.get("carteDeDemonstration").asText()).contains("vide");

        // On range derriere le test : la base et son utilisateur ne survivent pas au scenario.
        try (java.sql.Connection cx = source.getConnection(); java.sql.Statement st = cx.createStatement()) {
            st.executeUpdate("DROP DATABASE IF EXISTS " + base);
            st.executeUpdate("DROP USER IF EXISTS " + base);
        }
    }

    @Test @Order(7) void lesDroitsDeChacun() throws Exception {
        // Un compte support : il regarde, il ne touche pas.
        poster("/api/utilisateurs", Map.of("username", "support1", "fullName", "Support",
                "password", "support12345", "role", "SUPPORT"), 200);
        String jetonAdmin = jeton;
        jeton = json(poster("/api/auth/connexion",
                Map.of("username", "support1", "password", "support12345"), 200)).get("token").asText();

        lire("/api/clients");   // lire : autorise
        MvcResult refus = poster("/api/clients", Map.of("raisonSociale", "Interdit"), 403);
        assertThat(refus.getResponse().getContentAsString()).contains("SUPPORT").contains("administrateur");

        jeton = jetonAdmin;
    }

    @Test @Order(8) void leTableauDeBordDitLEssentiel() throws Exception {
        JsonNode t = lire("/api/tableau-de-bord");
        assertThat(t.get("clients").asLong()).isPositive();
        assertThat(t.get("caisses").asLong()).isPositive();
        assertThat(t.get("recurrentMensuel").decimalValue()).isEqualByComparingTo("49.000");
        // Le journal garde la trace de tout ce qui vient d'etre fait.
        assertThat(lire("/api/journal")).isNotEmpty();
    }
}
