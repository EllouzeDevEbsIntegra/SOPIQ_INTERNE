package com.poscaisse.it;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.poscaisse.BaseDeTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@EnabledIfEnvironmentVariable(named = "POSCAISSE_IT", matches = "true")
class AuditConfidentialiteIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @DynamicPropertySource static void base(DynamicPropertyRegistry r) { BaseDeTest.neuve(r, "poscaisse_audit_confidentialite_it"); }

    private String connexion(String identifiant, String secret) throws Exception {
        var reponse = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(java.util.Map.of("username", identifiant, "password", secret))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return "Bearer " + json.readTree(reponse).get("token").asText();
    }

    private String caissier() throws Exception {
        var reponse = mvc.perform(post("/api/auth/pin").contentType(MediaType.APPLICATION_JSON).content("{\"pin\":\"1234\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return "Bearer " + json.readTree(reponse).get("token").asText();
    }

    @Test void lesReglagesPrivesExigentLaPermissionDeGestion() throws Exception {
        mvc.perform(get("/api/settings").header("Authorization", caissier())).andExpect(status().isForbidden());
        mvc.perform(get("/api/settings").header("Authorization", connexion("admin", "mot-de-passe-de-test-0910")))
                .andExpect(status().isOk()).andExpect(jsonPath("$['finance.marginPercent']").exists());
    }

    @Test void leCatalogueDeVenteNeRevelePasLePrixAchat() throws Exception {
        jdbc.update("update product set purchase_price = 2.125");
        mvc.perform(get("/api/pos/catalog").header("Authorization", caissier()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.products[0].purchasePrice").doesNotExist());
    }

    @Test void changerLaDisponibiliteNeRevelePasLePrixAchat() throws Exception {
        long id = jdbc.queryForObject("select min(id) from product where active", Long.class);
        jdbc.update("update product set purchase_price = 2.125 where id = ?", id);
        mvc.perform(patch("/api/pos/products/" + id + "/availability").header("Authorization", caissier())
                .contentType(MediaType.APPLICATION_JSON).content("{\"available\":true}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.purchasePrice").doesNotExist());
    }
}
