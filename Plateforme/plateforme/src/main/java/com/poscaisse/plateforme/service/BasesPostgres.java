package com.poscaisse.plateforme.service;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Les gestes PostgreSQL de la plateforme : creer une base, la fermer, la refaire a neuf.
 *
 * POURQUOI CES INSTRUCTIONS NE SONT PAS PARAMETREES. CREATE DATABASE et GRANT n'acceptent
 * pas de parametre lie : le nom doit entrer dans la chaine. La protection est donc en
 * amont, et elle est stricte - {@link #nom(String)} n'accepte que des minuscules, des
 * chiffres et des soulignes, et ces noms sont fabriques par le code a partir du code
 * client, jamais saisis par quelqu'un.
 */
@Service @RequiredArgsConstructor
public class BasesPostgres {
    private static final Logger log = LoggerFactory.getLogger(BasesPostgres.class);

    /**
     * Le prefixe des bases de DEMONSTRATION, et la frontiere de securite du logiciel.
     *
     * {@link #remettreANeuf} supprime une base. Elle refuse tout nom qui ne commence pas
     * par ce prefixe : la base d'un client s'appelle << pos_cli0001_cafe >> et ne peut
     * donc jamais y passer, meme sur une erreur d'appel ailleurs dans le code.
     */
    public static final String PREFIXE_DEMO = "posdemo_";

    private final DataSource source;

    public boolean existe(String base) {
        return avec(st -> {
            try (ResultSet r = st.executeQuery("SELECT 1 FROM pg_database WHERE datname = '" + nom(base) + "'")) {
                return r.next();
            }
        });
    }

    /** Cree le role, s'il n'est pas deja la. Le mot de passe n'est jamais relu ensuite. */
    public void creerRole(String role, String motDePasse) {
        avec(st -> {
            try (ResultSet r = st.executeQuery("SELECT 1 FROM pg_roles WHERE rolname = '" + nom(role) + "'")) {
                if (r.next()) return null;
            }
            st.executeUpdate("CREATE USER " + nom(role) + " WITH PASSWORD '" + motDePasse.replace("'", "''") + "'");
            return null;
        });
    }

    public void creerBase(String base, String proprietaire) {
        avec(st -> {
            st.executeUpdate("CREATE DATABASE " + nom(base) + " OWNER " + nom(proprietaire));
            cloisonner(st, base, proprietaire);
            return null;
        });
    }

    /**
     * Fermer la base a tout le monde sauf a son proprietaire.
     *
     * PostgreSQL accorde CONNECT a PUBLIC sur toute base neuve : sans ce retrait, le compte
     * d'un client peut ouvrir la base d'un autre. Il n'y lit aucune donnee - les tables
     * appartiennent a l'autre role - mais il entre, et lit le catalogue partage : le nom de
     * toutes les bases, donc de tous nos clients.
     */
    public void cloisonner(String base, String proprietaire) {
        avec(st -> { cloisonner(st, base, proprietaire); return null; });
    }

    /**
     * REFAIRE UNE BASE DE DEMONSTRATION A NEUF.
     *
     * On supprime et on recree, plutot que de nettoyer. Nettoyer serait approximatif : le
     * prospect a pu changer un prix, ajouter un article, renommer la maison, ouvrir un
     * compte. Il faudrait deviner tout ce qu'il a touche. Une base vide, elle, redevient
     * exactement une demonstration neuve au demarrage suivant - c'est la caisse elle-meme
     * qui repose son schema, ses reglages metier et sa carte, par le chemin deja teste du
     * tout premier allumage.
     *
     * LE ROLE SURVIT, ET C'EST VOULU : son mot de passe est ecrit dans le fichier de
     * service du poste. Le recreer obligerait a reecrire ce fichier a chaque remise a zero.
     *
     * WITH (FORCE) : un navigateur reste parfois connecte quelques secondes apres l'arret
     * du processus, et la suppression attendrait indefiniment.
     */
    public void remettreANeuf(String base, String proprietaire) {
        String b = nom(base);
        if (!b.startsWith(PREFIXE_DEMO))
            throw new ErreurMetier("Refus de supprimer « " + b + " » : seules les bases de démonstration ("
                    + PREFIXE_DEMO + "…) peuvent être remises à zéro.");
        avec(st -> {
            st.executeUpdate("DROP DATABASE IF EXISTS " + b + " WITH (FORCE)");
            st.executeUpdate("CREATE DATABASE " + b + " OWNER " + nom(proprietaire));
            cloisonner(st, b, proprietaire);
            return null;
        });
        log.info("Base de démonstration « {} » remise à son état initial.", b);
    }

    // ------------------------------------------------------------------ mecanique

    private void cloisonner(Statement st, String base, String proprietaire) throws SQLException {
        st.executeUpdate("REVOKE CONNECT ON DATABASE " + nom(base) + " FROM PUBLIC");
        st.executeUpdate("GRANT CONNECT ON DATABASE " + nom(base) + " TO " + nom(proprietaire));
    }

    /** Un nom d'objet PostgreSQL fabrique par nous : minuscules, chiffres, soulignes. */
    private static String nom(String n) {
        if (n == null || !n.matches("[a-z][a-z0-9_]{0,62}"))
            throw new ErreurMetier("Nom d'objet PostgreSQL refusé : « " + n + " ».");
        return n;
    }

    private interface Geste<T> { T faire(Statement st) throws SQLException; }

    private <T> T avec(Geste<T> g) {
        try (Connection cx = source.getConnection(); Statement st = cx.createStatement()) {
            return g.faire(st);
        } catch (SQLException e) {
            throw new ErreurMetier("Opération PostgreSQL impossible : " + e.getMessage());
        }
    }
}
