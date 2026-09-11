package com.poscaisse.plateforme;

import com.poscaisse.plateforme.web.ApiControleur;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.sql.DriverManager;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = {
        "plateforme.admin-password=Secret-initial-audit-2026",
        "spring.jpa.properties.hibernate.generate_statistics=true"
})
@EnabledIfEnvironmentVariable(named = "PLATEFORME_IT", matches = "true")
class ClientsPerformanceIntegrationTest {
    @Autowired JdbcTemplate jdbc;
    @Autowired ApiControleur api;
    @Autowired EntityManagerFactory emf;

    @DynamicPropertySource
    static void base(DynamicPropertyRegistry r) throws Exception {
        String hote = System.getenv().getOrDefault("PLATEFORME_DB_HOST", "127.0.0.1");
        if (!hote.equals("127.0.0.1") && !hote.equals("localhost"))
            throw new IllegalStateException("Cet audit exige PostgreSQL local.");
        String port = System.getenv().getOrDefault("PLATEFORME_DB_PORT", "5432");
        String compte = System.getenv().getOrDefault("PLATEFORME_DB_USER", "postgres");
        String secret = System.getenv().getOrDefault("PLATEFORME_DB_PASSWORD", "postgres");
        String racine = "jdbc:postgresql://" + hote + ":" + port + "/";
        try (var cx = DriverManager.getConnection(racine + "postgres", compte, secret); var st = cx.createStatement()) {
            st.executeUpdate("DROP DATABASE IF EXISTS plateforme_audit_200_clients WITH (FORCE)");
            st.executeUpdate("CREATE DATABASE plateforme_audit_200_clients");
        }
        r.add("spring.datasource.url", () -> racine + "plateforme_audit_200_clients");
        r.add("spring.datasource.username", () -> compte);
        r.add("spring.datasource.password", () -> secret);
    }

    @Test
    void deuxCentsClientsRestentUnNombreBorneDeRequetes() {
        jdbc.update("""
                insert into client(code, raison_sociale, statut)
                select 'AUD-' || lpad(n::text, 4, '0'), 'Client audit ' || n, 'ACTIF'
                from generate_series(1, 200) n
                """);
        jdbc.update("""
                insert into abonnement(client_id, module, formule, nb_caisses, prix_mensuel, debut_le, statut)
                select id, 'SHOP', 'MENSUEL', 1, 49, current_date, 'ACTIF' from client where code like 'AUD-%'
                """);
        jdbc.update("""
                insert into facture(client_id, abonnement_id, numero, periode_debut, periode_fin,
                                     montant, emise_le, echeance_le, statut)
                select c.id, a.id, 'AUD-FAC-' || lpad(c.id::text, 6, '0'), current_date,
                       current_date, 49, current_date, current_date + 15, 'EMISE'
                from client c join abonnement a on a.client_id=c.id where c.code like 'AUD-%'
                """);
        jdbc.update("""
                insert into reglement(facture_id, montant, recu_le, moyen)
                select id, 10, current_date, 'VIREMENT' from facture where numero like 'AUD-FAC-%'
                """);

        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        List<Long> millisecondes = new ArrayList<>();
        long maxRequetes = 0;
        for (int i = 0; i < 12; i++) {
            stats.clear();
            long debut = System.nanoTime();
            assertThat(api.clients()).hasSize(200);
            millisecondes.add((System.nanoTime() - debut) / 1_000_000);
            maxRequetes = Math.max(maxRequetes, stats.getPrepareStatementCount());
        }
        Collections.sort(millisecondes);
        long mediane = millisecondes.get(millisecondes.size() / 2);
        long p95 = millisecondes.get((int) Math.ceil(millisecondes.size() * .95) - 1);
        System.out.printf("AUDIT_CLIENTS_200 mediane_ms=%d p95_ms=%d requetes_max=%d%n", mediane, p95, maxRequetes);
        assertThat(maxRequetes).as("les requêtes doivent rester bornées, indépendamment du nombre de clients")
                .isLessThanOrEqualTo(15);
    }
}
