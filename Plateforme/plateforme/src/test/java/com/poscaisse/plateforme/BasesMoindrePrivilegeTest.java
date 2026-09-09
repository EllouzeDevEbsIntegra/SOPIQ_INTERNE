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
    private static final String REMISE = "posdemo_remise";
    private static final String POSE_DEHORS = "posdemo_pose_dehors";
    private static final String SECRET_DEMO = "essai-demo-2026";

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


    /**
     * ETEINDRE UNE DEMO : le geste que le bouton << Arrêter >> declenche.
     *
     * Il a echoue en production sur << must be owner of database posdemo_cafe >>, et le
     * scenario de creation ci-dessus ne pouvait pas le voir : l'appartenance au role
     * proprietaire etait prise APRES le DROP, alors que c'est le DROP qui l'exige. La
     * demo restait a moitie eteinte - processus tue, base intacte avec les saisies du
     * prospect - et l'ecran montrait une erreur PostgreSQL brute.
     *
     * La table temoin n'est pas decorative : sans elle, le test passerait meme si
     * remettreANeuf ne remettait rien a neuf.
     */
    @Test
    void uneDemoSeRemetANeufSansEtreProprietaireDeSaBase() throws SQLException {
        bases.creerRole(REMISE, SECRET_DEMO);
        bases.creerBase(REMISE, REMISE);
        dansLaBase(REMISE, "CREATE TABLE temoin (x int)");
        assertThat(tableExiste(REMISE, "temoin")).as("le témoin est bien posé").isTrue();

        bases.remettreANeuf(REMISE, REMISE);

        assertThat(bases.existe(REMISE)).as("la base est reconstruite").isTrue();
        assertThat(proprietaire(REMISE)).as("elle appartient toujours à la démo").isEqualTo(REMISE);
        assertThat(publicPeutSeConnecter(REMISE)).as("PUBLIC reste dehors").isFalse();
        assertThat(tableExiste(REMISE, "temoin")).as("ce que le prospect a saisi a disparu").isFalse();
    }

    /**
     * LE CONTRAT ENTRE LE SCRIPT D'INSTALLATION ET LE BACK-OFFICE.
     *
     * Les roles des six demonstrations ne sont pas crees par le back-office mais par
     * preparer-demos.sh, sous << postgres >>, parce qu'il faut en CHOISIR le mot de passe
     * pour l'ecrire dans le fichier systemd du poste. Le back-office se retrouve alors
     * devant un role qu'il n'a pas cree : PostgreSQL 16 ne lui donne aucun droit dessus,
     * et son GRANT echoue - << permission denied to grant role >>, le bouton ne demarre
     * rien. C'est exactement ce qui est arrive a cinq demos sur six, la sixieme ayant ete
     * creee la veille par le back-office lui-meme.
     *
     * Le script doit donc rendre au back-office l'etat qu'il aurait eu s'il avait cree le
     * role : l'ADMIN OPTION, et elle seule. Ce test fige ce contrat dans les deux sens -
     * sans elle rien ne marche, avec elle tout marche, et le compte qui provisionne ne
     * peut toujours pas endosser le role.
     */
    @Test
    void unRoleCreeHorsDuBackOfficeExigeLAdminOption() throws SQLException {
        enSuperUtilisateur("CREATE USER " + POSE_DEHORS + " WITH PASSWORD '" + SECRET_DEMO + "'");

        assertThatThrownBy(() -> bases.creerBase(POSE_DEHORS, POSE_DEHORS))
                .as("sans ADMIN OPTION, le back-office ne peut rien faire de ce rôle")
                .isInstanceOf(ErreurMetier.class)
                .hasMessageContaining("permission denied to grant role");

        enSuperUtilisateur("GRANT " + POSE_DEHORS + " TO " + ADMIN
                + " WITH ADMIN OPTION, INHERIT FALSE, SET FALSE");

        bases.creerBase(POSE_DEHORS, POSE_DEHORS);
        assertThat(bases.existe(POSE_DEHORS)).isTrue();
        assertThat(proprietaire(POSE_DEHORS)).isEqualTo(POSE_DEHORS);

        assertThatThrownBy(() -> {
            try (Connection cx = source(ADMIN, SECRET_ADMIN).getConnection(); Statement st = cx.createStatement()) {
                st.execute("SET ROLE " + POSE_DEHORS);
            }
        }).as("l'ADMIN OPTION administre le rôle, elle ne le prête pas")
          .hasMessageContaining("permission denied to set role");
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
            for (String n : new String[]{CLIENT, REMISE, POSE_DEHORS}) {
                st.executeUpdate("DROP DATABASE IF EXISTS " + n + " WITH (FORCE)");
                st.executeUpdate("DROP ROLE IF EXISTS " + n);
            }
            st.executeUpdate("DROP ROLE IF EXISTS " + ADMIN);
        }
    }

    /** Une instruction executee DANS la base, sous le compte de la demo elle-meme. */
    private static void dansLaBase(String base, String ordre) throws SQLException {
        DriverManagerDataSource ds = new DriverManagerDataSource();
        ds.setDriverClassName("org.postgresql.Driver");
        ds.setUrl("jdbc:postgresql://" + HOTE + ":" + PORT + "/" + base);
        ds.setUsername(base);
        ds.setPassword(SECRET_DEMO);
        try (Connection cx = ds.getConnection(); Statement st = cx.createStatement()) {
            st.executeUpdate(ordre);
        }
    }

    private static boolean tableExiste(String base, String table) throws SQLException {
        DriverManagerDataSource ds = new DriverManagerDataSource();
        ds.setDriverClassName("org.postgresql.Driver");
        ds.setUrl("jdbc:postgresql://" + HOTE + ":" + PORT + "/" + base);
        ds.setUsername(base);
        ds.setPassword(SECRET_DEMO);
        try (Connection cx = ds.getConnection();
             Statement st = cx.createStatement();
             ResultSet r = st.executeQuery("SELECT to_regclass('public." + table + "') IS NOT NULL")) {
            return r.next() && r.getBoolean(1);
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
