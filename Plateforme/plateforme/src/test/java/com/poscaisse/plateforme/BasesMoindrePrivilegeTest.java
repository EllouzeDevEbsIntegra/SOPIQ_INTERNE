package com.poscaisse.plateforme;

import com.poscaisse.plateforme.service.BasesPostgres;
import com.poscaisse.plateforme.service.ErreurMetier;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Creer une base SANS etre superutilisateur.
 *
 * CE QUE CE TEST PROTEGE, ET POURQUOI IL EXISTE. Les autres scenarios se connectent en
 * superutilisateur, a qui tout est permis : ils ne prouvent donc rien de ce que fait le
 * logiciel une fois installe. Sur le serveur, la plateforme tourne sous un compte qui n'a
 * que CREATEDB et CREATEROLE - le strict necessaire - et c'est la que PostgreSQL 16 a
 * refuse : << must be able to SET ROLE >>. Depuis la version 16, un role CREATEROLE qui
 * cree un role n'obtient plus le droit de l'endosser, et CREATE DATABASE ... OWNER
 * l'exige.
 *
 * Le defaut n'a donc ete vu qu'au premier deploiement, en cliquant sur un bouton. Ce
 * fichier rejoue cette situation-la : un role de moindre privilege, et les memes gestes.
 */
@EnabledIfEnvironmentVariable(named = "PLATEFORME_IT", matches = "true")
class BasesMoindrePrivilegeTest {

    private static final String HOTE = System.getenv().getOrDefault("PLATEFORME_DB_HOST", "localhost");
    private static final String PORT = System.getenv().getOrDefault("PLATEFORME_DB_PORT", "5432");
    private static final String SUPER_COMPTE = System.getenv().getOrDefault("PLATEFORME_DB_USER", "postgres");
    private static final String SUPER_SECRET = System.getenv().getOrDefault("PLATEFORME_DB_PASSWORD", "postgres");

    private static final String ADMIN = "essai_provisionneur";
    private static final String SECRET_ADMIN = "essai-provisionneur-2026";
    private static final String CLIENT = "posdemo_essai";

    private static BasesPostgres bases;

    @BeforeAll
    static void poserUnCompteDeMoindrePrivilege() throws SQLException {
        menage();
        enSuperUtilisateur("CREATE ROLE " + ADMIN + " LOGIN PASSWORD '" + SECRET_ADMIN + "' CREATEDB CREATEROLE");
        bases = new BasesPostgres(source(ADMIN, SECRET_ADMIN));
    }

    @AfterAll
    static void ranger() throws SQLException { menage(); }

    /**
     * Le geste complet, tel que le fait le bouton << Démarrer une démo >>.
     *
     * S'il echoue, il echoue exactement comme sur le serveur - et non avec un
     * superutilisateur qui masque le probleme.
     */
    @Test
    void unCompteSansPrivilegeCreeLaBaseEtLaReferme() throws SQLException {
        bases.creerRole(CLIENT, "un-mot-de-passe-quelconque");
        bases.creerBase(CLIENT, CLIENT);

        assertThat(bases.existe(CLIENT)).as("la base est créée").isTrue();
        assertThat(proprietaire(CLIENT)).as("elle appartient au client, pas au provisionneur").isEqualTo(CLIENT);
        assertThat(publicPeutSeConnecter(CLIENT)).as("PUBLIC est mis dehors").isFalse();

        /*
            ET SURTOUT : le provisionneur ne doit PAS pouvoir endosser le role du client.

            L'appartenance a ete accordee le temps de creer la base, puis retiree. Sans ce
            retrait, le compte qui provisionne pourrait devenir n'importe quel client et
            lire ses ventes - une porte ouverte pour un confort de deux instructions SQL.
        */
        assertThatThrownBy(() -> {
            try (Connection cx = source(ADMIN, SECRET_ADMIN).getConnection(); Statement st = cx.createStatement()) {
                st.execute("SET ROLE " + CLIENT);
            }
        }).hasMessageContaining("permission denied to set role");
    }

    /** Le garde-fou tient aussi ici : on ne supprime pas la base d'un client. */
    @Test
    void laBaseDUnClientNeSeRemetPasAZero() {
        assertThatThrownBy(() -> bases.remettreANeuf("pos_cli0001_cafe", "pos_cli0001_cafe"))
                .isInstanceOf(ErreurMetier.class)
                .hasMessageContaining("posdemo_");
    }

    // ------------------------------------------------------------------ mecanique

    private static DataSource source(String compte, String secret) {
        DriverManagerDataSource ds = new DriverManagerDataSource();
        ds.setDriverClassName("org.postgresql.Driver");
        ds.setUrl("jdbc:postgresql://" + HOTE + ":" + PORT + "/postgres");
        ds.setUsername(compte);
        ds.setPassword(secret);
        return ds;
    }

    private static void enSuperUtilisateur(String... ordres) throws SQLException {
        try (Connection cx = source(SUPER_COMPTE, SUPER_SECRET).getConnection(); Statement st = cx.createStatement()) {
            for (String o : ordres) st.executeUpdate(o);
        }
    }

    private static void menage() throws SQLException {
        try (Connection cx = source(SUPER_COMPTE, SUPER_SECRET).getConnection(); Statement st = cx.createStatement()) {
            st.executeUpdate("DROP DATABASE IF EXISTS " + CLIENT + " WITH (FORCE)");
            st.executeUpdate("DROP ROLE IF EXISTS " + CLIENT);
            st.executeUpdate("DROP ROLE IF EXISTS " + ADMIN);
        }
    }

    private static String proprietaire(String base) throws SQLException {
        return lire("select pg_get_userbyid(datdba) from pg_database where datname = '" + base + "'");
    }

    private static boolean publicPeutSeConnecter(String base) throws SQLException {
        return "t".equals(lire("select has_database_privilege('public', '" + base + "', 'CONNECT')"));
    }

    private static String lire(String requete) throws SQLException {
        try (Connection cx = source(SUPER_COMPTE, SUPER_SECRET).getConnection();
             Statement st = cx.createStatement();
             ResultSet r = st.executeQuery(requete)) {
            return r.next() ? String.valueOf(r.getObject(1)) : null;
        }
    }
}
