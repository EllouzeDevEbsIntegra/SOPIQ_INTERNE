package com.poscaisse.it;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * End-to-end API scenario against a real PostgreSQL (set POSCAISSE_IT=true and a reachable database).
 * Covers: PIN login, register opening, checkout with options + change, idempotent double submit, permission refusal,
 * mixed payment, cash movement, closure with cash difference.
 */
@SpringBootTest
@AutoConfigureMockMvc
@EnabledIfEnvironmentVariable(named = "POSCAISSE_IT", matches = "true")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class PosIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper om;
    static String cashierToken, managerToken; static long registerId, sessionId, cashId, cardId, cheeseId, fromageId, fritesId, cocaId, orderId;

    private JsonNode json(MvcResult r) throws Exception { return om.readTree(r.getResponse().getContentAsString()); }
    private MvcResult postJson(String url, String token, Object body, int status) throws Exception {
        return mvc.perform(post(url).header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(body))).andExpect(status().is(status)).andReturn();
    }
    private MvcResult putJson(String url, String token, Object body, int status) throws Exception {
        return mvc.perform(put(url).header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(body))).andExpect(status().is(status)).andReturn();
    }

    @Test @Order(1) void loginAndOpenRegister() throws Exception {
        JsonNode a = json(mvc.perform(post("/api/auth/pin").contentType(MediaType.APPLICATION_JSON).content("{\"pin\":\"1234\"}")).andExpect(status().isOk()).andReturn());
        cashierToken = a.get("token").asText();
        assertThat(a.get("user").get("roleCode").asText()).isEqualTo("CASHIER");
        managerToken = json(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("{\"username\":\"manager\",\"password\":\"manager123\"}")).andExpect(status().isOk()).andReturn()).get("token").asText();
        mvc.perform(post("/api/auth/pin").contentType(MediaType.APPLICATION_JSON).content("{\"pin\":\"0000\"}")).andExpect(status().isUnauthorized());

        JsonNode regs = json(mvc.perform(get("/api/pos/registers").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        JsonNode free = null; for (JsonNode r : regs) if (r.get("openSession").isNull()) { free = r; break; }
        assertThat(free).as("a free register").isNotNull();
        registerId = free.get("id").asLong();
        JsonNode s = json(postJson("/api/pos/session/open", cashierToken, java.util.Map.of("registerId", registerId, "openingFloat", 100), 200));
        sessionId = s.get("id").asLong();
        postJson("/api/pos/session/open", cashierToken, java.util.Map.of("registerId", registerId, "openingFloat", 100), 409);
    }

    @Test @Order(2) void checkoutWithOptionsChangeAndIdempotency() throws Exception {
        JsonNode cat = json(mvc.perform(get("/api/pos/catalog").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        for (JsonNode m : cat.get("paymentMethods")) { if (m.get("kind").asText().equals("CASH")) cashId = m.get("id").asLong(); if (m.get("kind").asText().equals("CARD")) cardId = m.get("id").asLong(); }
        for (JsonNode p : cat.get("products")) {
            String code = p.get("code").asText();
            if (code.equals("BUR-002")) { cheeseId = p.get("id").asLong(); for (JsonNode g : p.get("modifierGroups")) for (JsonNode m : g.get("modifiers")) if (m.get("name").asText().equals("Supplément fromage")) fromageId = m.get("id").asLong(); }
            if (code.equals("EXT-001")) fritesId = p.get("id").asLong();
            if (code.equals("BOI-002")) cocaId = p.get("id").asLong();
        }
        String ref = UUID.randomUUID().toString();
        String body = "{\"clientRef\":\"" + ref + "\",\"registerId\":" + registerId + ",\"lines\":[{\"productId\":" + cheeseId + ",\"quantity\":2,\"modifierIds\":[" + fromageId + "]},{\"productId\":" + fritesId + ",\"quantity\":2},{\"productId\":" + cocaId + ",\"quantity\":2}],\"payments\":[{\"paymentMethodId\":" + cashId + ",\"amount\":28,\"tendered\":50}]}";
        JsonNode o = json(mvc.perform(post("/api/pos/checkout").header("Authorization", "Bearer " + cashierToken).contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isOk()).andReturn());
        orderId = o.get("id").asLong();
        assertThat(o.get("total").decimalValue()).isEqualByComparingTo("28.000");
        assertThat(o.get("changeAmount").decimalValue()).isEqualByComparingTo("22.000");
        assertThat(o.get("ticketNumber").asText()).isNotBlank();
        assertThat(o.get("printJobs").size()).isGreaterThanOrEqualTo(2);
        JsonNode again = json(mvc.perform(post("/api/pos/checkout").header("Authorization", "Bearer " + cashierToken).contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isOk()).andReturn());
        assertThat(again.get("id").asLong()).isEqualTo(orderId);
    }

    @Test @Order(3) void mixedPaymentAndValidationErrors() throws Exception {
        String lines = "[{\"productId\":" + cheeseId + ",\"quantity\":3},{\"productId\":" + cocaId + ",\"quantity\":4}]"; // 22.5 + 10 = 32.5
        String ok = "{\"clientRef\":\"" + UUID.randomUUID() + "\",\"registerId\":" + registerId + ",\"lines\":" + lines + ",\"payments\":[{\"paymentMethodId\":" + cashId + ",\"amount\":20,\"tendered\":20},{\"paymentMethodId\":" + cardId + ",\"amount\":12.5}]}";
        JsonNode o = json(mvc.perform(post("/api/pos/checkout").header("Authorization", "Bearer " + cashierToken).contentType(MediaType.APPLICATION_JSON).content(ok)).andExpect(status().isOk()).andReturn());
        assertThat(o.get("total").decimalValue()).isEqualByComparingTo("32.500");
        assertThat(o.get("payments").size()).isEqualTo(2);
        String insufficient = "{\"clientRef\":\"" + UUID.randomUUID() + "\",\"registerId\":" + registerId + ",\"lines\":" + lines + ",\"payments\":[{\"paymentMethodId\":" + cardId + ",\"amount\":10}]}";
        mvc.perform(post("/api/pos/checkout").header("Authorization", "Bearer " + cashierToken).contentType(MediaType.APPLICATION_JSON).content(insufficient)).andExpect(status().isBadRequest()).andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("insuffisant")));
        String highDiscount = "{\"clientRef\":\"" + UUID.randomUUID() + "\",\"registerId\":" + registerId + ",\"discountPercent\":30,\"lines\":" + lines + ",\"payments\":[{\"paymentMethodId\":" + cardId + ",\"amount\":22.75}]}";
        mvc.perform(post("/api/pos/checkout").header("Authorization", "Bearer " + cashierToken).contentType(MediaType.APPLICATION_JSON).content(highDiscount)).andExpect(status().isForbidden());
    }

    @Test @Order(4) void permissionsAreEnforcedServerSide() throws Exception {
        mvc.perform(get("/api/users").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isForbidden());
        mvc.perform(get("/api/users").header("Authorization", "Bearer " + managerToken)).andExpect(status().isForbidden());
        mvc.perform(get("/api/pos/catalog")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/orders/" + orderId + "/cancel").header("Authorization", "Bearer " + cashierToken).contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"x\"}")).andExpect(status().isForbidden());
        mvc.perform(get("/api/reports/dashboard").header("Authorization", "Bearer " + managerToken)).andExpect(status().isOk());
    }

    @Test @Order(5) void movementsRefundAndClosure() throws Exception {
        postJson("/api/pos/session/" + sessionId + "/movements", cashierToken, java.util.Map.of("type", "OUT", "reason", "Achat urgent", "amount", 20, "comment", "Achat pain"), 200);
        JsonNode refunded = json(postJson("/api/orders/" + orderId + "/refund", managerToken, java.util.Map.of("amount", 5, "reason", "Erreur article", "paymentMethodId", cashId), 200));
        assertThat(refunded.get("status").asText()).isEqualTo("PARTIALLY_REFUNDED");
        JsonNode sum = json(mvc.perform(get("/api/pos/session/" + sessionId + "/summary").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        // 100 + (28 + 20) cash - 5 refund - 20 out = 123
        assertThat(sum.get("expectedCash").decimalValue()).isEqualByComparingTo("123.000");
        JsonNode closed = json(postJson("/api/pos/session/" + sessionId + "/close", cashierToken, java.util.Map.of("countedCash", 120, "note", "test"), 200));
        assertThat(closed.get("cashDifference").decimalValue()).isEqualByComparingTo("-3.000");
        assertThat(closed.get("status").asText()).isEqualTo("CLOSED");
        postJson("/api/pos/session/" + sessionId + "/close", cashierToken, java.util.Map.of("countedCash", 120), 409);
    }

    /**
     * La numérotation des tickets, de bout en bout : le format, la portée du compteur et
     * le compteur lui-même.
     *
     * Ce test tient les deux promesses que l'ancien mécanisme ne pouvait pas tenir en même
     * temps : imprimer l'année SANS repartir à 1 le 1er janvier, et repartir à 1 chaque
     * jour. Il vérifie aussi qu'un réglage fabriquant des doublons est refusé à
     * l'enregistrement — pas devant le client — et qu'on ne peut pas ramener le compteur
     * sur un numéro déjà imprimé.
     */
    @Test @Order(6) void ticketNumberingScopeFormatAndCounter() throws Exception {
        String admin = json(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"admin\",\"password\":\"admin123\"}")).andExpect(status().isOk()).andReturn())
                .get("token").asText();
        String an = String.valueOf(java.time.Year.now(java.time.ZoneId.of("Africa/Tunis")).getValue());

        // Ce que la caisse porte aujourd'hui : le réglage livré, dit explicitement.
        JsonNode etat = json(mvc.perform(get("/api/ticket-numbering").header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk()).andReturn());
        assertThat(etat.get("resetPeriod").asText()).isEqualTo("YEARLY");
        assertThat(etat.get("perPos").asBoolean()).isTrue();
        assertThat(etat.get("problems")).isEmpty();
        assertThat(etat.get("sample").asText()).contains(an);

        // Une remise à zéro qui ne se lit pas sur le ticket : refusée, et elle dit pourquoi.
        JsonNode mauvais = json(postJson("/api/ticket-numbering/preview", admin,
                java.util.Map.of("pattern", "{SEQ:6}", "resetPeriod", "DAILY", "perPos", false), 200));
        assertThat(mauvais.get("problems")).isNotEmpty();
        assertThat(mauvais.get("sample").isNull()).as("pas d'exemple pour un réglage qui ne tient pas").isTrue();
        mvc.perform(put("/api/ticket-numbering").header("Authorization", "Bearer " + admin)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"pattern\":\"{SEQ:6}\",\"resetPeriod\":\"DAILY\",\"perPos\":false}"))
                .andExpect(status().isBadRequest());

        // L'année imprimée SANS remise à zéro : impossible avant, la portée était devinée du format.
        JsonNode continu = json(putJson("/api/ticket-numbering", admin,
                java.util.Map.of("pattern", "{POS}-{YYYY}-{SEQ:6}", "resetPeriod", "NONE", "perPos", true, "perRegister", false), 200));
        assertThat(continu.get("sample").asText()).contains(an);
        assertThat(continu.get("scopeKey").asText()).as("le compteur ne se découpe plus par année").doesNotContain(an);

        // Et l'inverse : repartir à 1 chaque jour, la date étant bien imprimée.
        JsonNode jour = json(putJson("/api/ticket-numbering", admin,
                java.util.Map.of("pattern", "{POS}-{YYYY}{MM}{DD}-{SEQ:4}", "resetPeriod", "DAILY", "perPos", true, "perRegister", false), 200));
        String aujourdhui = java.time.LocalDate.now(java.time.ZoneId.of("Africa/Tunis")).toString();
        assertThat(jour.get("scopeKey").asText()).endsWith(aujourdhui);
        assertThat(jour.get("problems")).isEmpty();

        // Le numéro annoncé est celui qui sort vraiment de la caisse.
        long sessionDuJour = json(postJson("/api/pos/session/open", cashierToken,
                java.util.Map.of("registerId", registerId, "openingFloat", 0), 200)).get("id").asLong();
        String attendu = jour.get("sample").asText();
        JsonNode vente = json(postJson("/api/pos/checkout", cashierToken, java.util.Map.of(
                "clientRef", UUID.randomUUID().toString(), "registerId", registerId,
                "lines", java.util.List.of(java.util.Map.of("productId", cocaId, "quantity", 1)),
                "payments", java.util.List.of(java.util.Map.of("paymentMethodId", cashId, "amount", 5, "tendered", 5))), 200));
        assertThat(vente.get("ticketNumber").asText()).isEqualTo(attendu);

        // Reprendre la main sur le compteur : en dessous de ce qui est déjà imprimé, c'est non.
        String cle = json(mvc.perform(get("/api/ticket-numbering").header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk()).andReturn()).get("scopeKey").asText();
        mvc.perform(put("/api/ticket-numbering/counter").header("Authorization", "Bearer " + admin)
                .contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(
                        java.util.Map.of("scopeKey", cle, "nextValue", 1))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("déjà été imprimé")));

        JsonNode pose = json(putJson("/api/ticket-numbering/counter", admin,
                java.util.Map.of("scopeKey", cle, "nextValue", 500), 200));
        assertThat(pose.get("nextValue").asLong()).isEqualTo(500);
        JsonNode vente500 = json(postJson("/api/pos/checkout", cashierToken, java.util.Map.of(
                "clientRef", UUID.randomUUID().toString(), "registerId", registerId,
                "lines", java.util.List.of(java.util.Map.of("productId", cocaId, "quantity", 1)),
                "payments", java.util.List.of(java.util.Map.of("paymentMethodId", cashId, "amount", 5, "tendered", 5))), 200));
        assertThat(vente500.get("ticketNumber").asText()).endsWith("0500");

        // Un compteur d'une autre portée ne s'écrit pas : le corriger ne changerait rien.
        mvc.perform(put("/api/ticket-numbering/counter").header("Authorization", "Bearer " + admin)
                .contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(
                        java.util.Map.of("scopeKey", "TICKET:AUTRE|1999-01-01", "nextValue", 3))))
                .andExpect(status().isBadRequest());

        postJson("/api/pos/session/" + sessionDuJour + "/close", cashierToken,
                java.util.Map.of("countedCash", 10), 200);
        putJson("/api/ticket-numbering", admin, java.util.Map.of(
                "pattern", "{POS}-{YYYY}-{SEQ:6}", "resetPeriod", "YEARLY", "perPos", true, "perRegister", false), 200);
    }

    /**
     * Reproduit le scénario réel : import d'une carte en mode « remplacer », qui ne peut que
     * désactiver les produits déjà vendus, puis nettoyage définitif. Vérifie que sans remise à
     * zéro des ventes rien n'est supprimé (et que l'utilisateur est averti), et qu'avec elle il
     * ne reste que le catalogue actif. Dernier test : il vide volontairement la base.
     */
    @Test @Order(7) void purgeRemovesInactiveCatalogOnlyWithSalesReset() throws Exception {
        String adminToken = json(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"admin\",\"password\":\"admin123\"}")).andExpect(status().isOk()).andReturn())
                .get("token").asText();

        String tinyCatalog = """
                {"label":"Carte de test","categories":[{"name":"TEST"}],
                 "products":[{"code":"T-001","name":"Article test","category":"TEST","price":1.5}]}""";
        JsonNode imported = json(mvc.perform(post("/api/catalog/import?replace=true")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(tinyCatalog)).andExpect(status().isOk()).andReturn());
        assertThat(imported.get("productsDeactivated").asInt())
                .as("les produits déjà vendus ne peuvent qu'être désactivés").isGreaterThan(0);

        // Sans remise à zéro : rien n'est supprimé, mais l'utilisateur est averti pourquoi.
        JsonNode kept = json(postJson("/api/catalog/purge", adminToken, java.util.Map.of(), 200));
        assertThat(kept.get("salesReset").asBoolean()).isFalse();
        assertThat(kept.get("productsDeleted").asInt()).isZero();
        assertThat(kept.get("warnings")).isNotEmpty();
        assertThat(kept.get("productsLeft").asInt()).isGreaterThan(1);

        // Avec remise à zéro : ventes effacées, puis seul le catalogue actif subsiste.
        JsonNode purged = json(postJson("/api/catalog/purge?resetSales=true", adminToken, java.util.Map.of(), 200));
        assertThat(purged.get("salesReset").asBoolean()).isTrue();
        assertThat(purged.get("salesRowsDeleted").asInt()).isPositive();
        assertThat(purged.get("productsLeft").asInt()).isEqualTo(1);
        assertThat(purged.get("categoriesLeft").asInt()).isEqualTo(1);
        assertThat(purged.get("warnings")).isEmpty();

        // Le POS reste utilisable : catalogue cohérent et numérotation repartie de zéro.
        JsonNode cat = json(mvc.perform(get("/api/pos/catalog").header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk()).andReturn());
        assertThat(cat.get("products").size()).isEqualTo(1);
        assertThat(cat.get("products").get(0).get("code").asText()).isEqualTo("T-001");
    }
}
