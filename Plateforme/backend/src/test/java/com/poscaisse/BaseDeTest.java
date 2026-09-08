package com.poscaisse;

import org.springframework.test.context.DynamicPropertyRegistry;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Une base neuve, refaite avant chaque scenario.
 *
 * POURQUOI CHACUN LA SIENNE. Deux raisons, trouvees l'une apres l'autre.
 *
 * Les scenarios de DEMARRAGE observent ce qui se passe la toute premiere fois qu'une
 * caisse s'allume : a la deuxieme execution ils trouveraient une societe deja
 * enregistree, l'amorcage ne ferait rien - a juste titre - et le test verifierait le
 * travail du test precedent.
 *
 * Le scenario de VENTE, lui, laisse une caisse ouverte, des tickets numerotes et un
 * catalogue purge. Rejoue sur la meme base, il recevait 409 sur l'ouverture de caisse et
 * 404 sur des articles que sa propre purge avait supprimes. Il ne passait qu'une fois,
 * sur une base que quelqu'un avait pense a creer a la main - et cela ne se voyait qu'au
 * deuxieme lancement, souvent des mois plus tard.
 */
public final class BaseDeTest {
    private BaseDeTest() {}

    private static final String HOTE = System.getenv().getOrDefault("POSCAISSE_DB_HOST", "localhost");
    private static final String PORT = System.getenv().getOrDefault("POSCAISSE_DB_PORT", "5432");
    private static final String COMPTE = System.getenv().getOrDefault("POSCAISSE_DB_USER", "postgres");
    private static final String SECRET = System.getenv().getOrDefault("POSCAISSE_DB_PASSWORD", "postgres");

    public static void neuve(DynamicPropertyRegistry r, String nom) {
        String administration = "jdbc:postgresql://" + HOTE + ":" + PORT + "/postgres";
        try (Connection cx = DriverManager.getConnection(administration, COMPTE, SECRET);
             Statement st = cx.createStatement()) {
            // FORCE : une execution interrompue laisse parfois une connexion ouverte, et
            // la suppression attendrait indefiniment.
            st.executeUpdate("DROP DATABASE IF EXISTS " + nom + " WITH (FORCE)");
            st.executeUpdate("CREATE DATABASE " + nom);
        } catch (SQLException e) {
            throw new IllegalStateException("Base de test « " + nom + " » impossible à préparer : " + e.getMessage(), e);
        }
        r.add("spring.datasource.url", () -> "jdbc:postgresql://" + HOTE + ":" + PORT + "/" + nom);
        r.add("spring.datasource.username", () -> COMPTE);
        r.add("spring.datasource.password", () -> SECRET);
    }
}
