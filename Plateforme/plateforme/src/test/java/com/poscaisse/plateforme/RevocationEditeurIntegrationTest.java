package com.poscaisse.plateforme;

import com.poscaisse.plateforme.domain.EditeurUser;
import com.poscaisse.plateforme.domain.Enums;
import com.poscaisse.plateforme.repository.EditeurUserRepo;
import com.poscaisse.plateforme.security.JwtService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.sql.DriverManager;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "plateforme.admin-password=Secret-initial-audit-2026")
@AutoConfigureMockMvc
@EnabledIfEnvironmentVariable(named = "PLATEFORME_IT", matches = "true")
class RevocationEditeurIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired EditeurUserRepo users;
    @Autowired JwtService jwt;

    @DynamicPropertySource
    static void base(DynamicPropertyRegistry r) throws Exception {
        String hote = System.getenv().getOrDefault("PLATEFORME_DB_HOST", "127.0.0.1");
        if (!hote.equals("127.0.0.1") && !hote.equals("localhost"))
            throw new IllegalStateException("Cet audit exige PostgreSQL local.");
        String url = "jdbc:postgresql://" + hote + ":" + System.getenv().getOrDefault("PLATEFORME_DB_PORT", "5432") + "/";
        String compte = System.getenv().getOrDefault("PLATEFORME_DB_USER", "postgres");
        String secret = System.getenv().getOrDefault("PLATEFORME_DB_PASSWORD", "postgres");
        try (var cx = DriverManager.getConnection(url + "postgres", compte, secret); var st = cx.createStatement()) {
            st.executeUpdate("DROP DATABASE IF EXISTS plateforme_audit_revocation WITH (FORCE)");
            st.executeUpdate("CREATE DATABASE plateforme_audit_revocation");
        }
        r.add("spring.datasource.url", () -> url + "plateforme_audit_revocation");
        r.add("spring.datasource.username", () -> compte);
        r.add("spring.datasource.password", () -> secret);
    }

    private EditeurUser creer() {
        EditeurUser u = new EditeurUser();
        u.setUsername("audit-" + UUID.randomUUID());
        u.setFullName("Compte audit isolé");
        u.setPasswordHash("inutilise-connexion-par-jeton-du-test");
        u.setRole(Enums.Role.ADMIN);
        return users.save(u);
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/clients", "/api/clients/999999", "/api/abonnements/999999", "/api/journal",
            "/api/demos", "/api/tableau-de-bord", "/api/factures/en-retard", "/api/clients/999999/factures", "/api/auth/moi"})
    void unCompteDesactiveNePeutPlusLireAvecSonAncienJeton(String chemin) throws Exception {
        EditeurUser u = creer();
        String token = jwt.pour(u);
        u.setActive(false);
        users.save(u);
        mvc.perform(get(chemin).header("Authorization", "Bearer " + token)).andExpect(status().isUnauthorized());
    }

    @Test void unCompteSupprimeNePeutPlusLireLesClients() throws Exception {
        EditeurUser u = creer();
        String token = jwt.pour(u);
        users.delete(u);
        mvc.perform(get("/api/clients").header("Authorization", "Bearer " + token)).andExpect(status().isUnauthorized());
    }

    @Test void unCompteDesactiveNePeutPlusModifierAvecSonAncienJeton() throws Exception {
        EditeurUser u = creer();
        String token = jwt.pour(u);
        u.setActive(false);
        users.save(u);
        mvc.perform(post("/api/clients").header("Authorization", "Bearer " + token)
                .contentType("application/json").content("{\"raisonSociale\":\"Ne doit pas être créé\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test void leRoleCourantRetireLesDroitsSansAttendreLExpirationDuJeton() throws Exception {
        EditeurUser u = creer();
        String token = jwt.pour(u);
        u.setRole(Enums.Role.SUPPORT);
        users.save(u);
        mvc.perform(get("/api/clients").header("Authorization", "Bearer " + token)).andExpect(status().isOk());
        mvc.perform(get("/api/utilisateurs").header("Authorization", "Bearer " + token)).andExpect(status().isForbidden());
    }

    @Test void unJetonDUnAutreSignataireNeLitPasLesClients() throws Exception {
        var cle = io.jsonwebtoken.Jwts.SIG.HS256.key().build();
        String token = io.jsonwebtoken.Jwts.builder().subject("1")
                .claim("role", "ADMIN").claim("username", "admin").signWith(cle).compact();
        mvc.perform(get("/api/clients").header("Authorization", "Bearer " + token)).andExpect(status().isUnauthorized());
    }
}
