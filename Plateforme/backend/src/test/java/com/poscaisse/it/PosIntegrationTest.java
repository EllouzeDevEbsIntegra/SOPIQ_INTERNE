package com.poscaisse.it;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.Map;
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
     * La marge bénéficiaire et l'état de caisse.
     *
     * Le bénéfice se calcule sur le CHIFFRE D'AFFAIRES, pas sur le tiroir : une vente par
     * carte y compte même si l'argent n'est pas là, et une sortie de caisse ne l'entame
     * pas. La session de ce scénario le prouve d'elle-même — elle a encaissé par carte et
     * sorti 20 dinars, si bien que le CA et les espèces théoriques ne se ressemblent pas.
     *
     * Et tant qu'aucun taux n'est posé, rien ne s'affiche : un « bénéfice 0,000 » se
     * lirait comme une journée sans marge.
     */
    @Test @Order(6) void margeBeneficiaireEtEtatDeCaisse() throws Exception {
        String url = "/api/pos/session/" + sessionId;
        JsonNode sans = json(mvc.perform(get(url + "/summary").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        assertThat(sans.get("marginPercent").decimalValue()).as("aucun taux livré").isEqualByComparingTo("0");
        assertThat(sans.get("estimatedProfit").decimalValue()).isEqualByComparingTo("0.000");
        String muet = json(mvc.perform(get(url + "/report").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn()).get("content").asText();
        assertThat(muet).as("sans taux, l'état ne parle pas de bénéfice").doesNotContain("BÉNÉFICE");

        // Le taux se pose au back-office, avec les droits qui vont avec.
        String admin = json(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"admin\",\"password\":\"admin123\"}")).andExpect(status().isOk()).andReturn()).get("token").asText();
        putJson("/api/settings", admin, java.util.Map.of("finance.marginPercent", "25"), 200);

        JsonNode avec = json(mvc.perform(get(url + "/summary").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        java.math.BigDecimal ca = avec.get("revenue").decimalValue();
        java.math.BigDecimal especes = avec.get("expectedCash").decimalValue();
        assertThat(avec.get("marginPercent").decimalValue()).isEqualByComparingTo("25");
        assertThat(avec.get("estimatedProfit").decimalValue())
                .as("25 % du chiffre d'affaires")
                .isEqualByComparingTo(ca.multiply(new java.math.BigDecimal("0.25")).setScale(3, java.math.RoundingMode.HALF_UP));
        assertThat(ca).as("le CA n'est pas le contenu du tiroir").isNotEqualByComparingTo(especes);
        assertThat(avec.get("estimatedProfit").decimalValue())
                .as("le bénéfice ne se calcule pas sur les espèces")
                .isNotEqualByComparingTo(especes.multiply(new java.math.BigDecimal("0.25")).setScale(3, java.math.RoundingMode.HALF_UP));

        JsonNode etat = json(mvc.perform(get(url + "/report").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        String papier = etat.get("content").asText();
        assertThat(etat.get("title").asText()).isEqualTo("État de caisse");
        assertThat(papier).contains("ÉTAT DE CAISSE").contains("CHIFFRE D'AFFAIRES").contains("BÉNÉFICE ESTIMÉ")
                .contains("Marge appliquée").contains("25 %")
                // la session est clôturée : l'état porte le compte réel et l'écart
                .contains("Espèces comptées").contains("ÉCART");
        assertThat(papier).as("le montant du bénéfice est sur le papier")
                .contains(com.poscaisse.printing.ReceiptRenderer.money(avec.get("estimatedProfit").decimalValue(), 3));

        /*
            Les especes ne se lisent qu'UNE fois, en haut, avec le fond de caisse.
            La version precedente les reprenait dans le detail des moyens de paiement,
            sous un total qui, lui, les excluait : trois lectures du meme chiffre et un
            total qui ne correspondait a aucune des trois.
        */
        String blocPaiements = papier.substring(papier.indexOf("AUTRES PAIEMENTS"), papier.indexOf("Tickets /"));
        assertThat(blocPaiements).as("le detail des autres paiements ne reprend pas les especes")
                .doesNotContain("Espèces");
        assertThat(papier.split("Espèces", -1).length - 1)
                .as("« Espèces » n'apparaît que dans le bloc du tiroir").isLessThanOrEqualTo(2);

        // On repose le réglage : les tests suivants ne doivent rien hériter de celui-ci.
        putJson("/api/settings", admin, java.util.Map.of("finance.marginPercent", "0"), 200);
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
    @Test @Order(7) void ticketNumberingScopeFormatAndCounter() throws Exception {
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

        // Ce que le CLIENT lit peut être court, alors que la référence reste entière en base.
        JsonNode court = json(putJson("/api/ticket-numbering", admin, java.util.Map.of(
                "pattern", "{POS}-{YYYY}{MM}{DD}-{SEQ:4}", "resetPeriod", "DAILY",
                "perPos", true, "perRegister", false, "displayPattern", "{SEQ:3}"), 200));
        assertThat(court.get("sample").asText()).contains(aujourdhui.replace("-", ""));
        assertThat(court.get("displaySample").asText()).doesNotContain(an).hasSize(3);

        JsonNode venteCourte = json(postJson("/api/pos/checkout", cashierToken, java.util.Map.of(
                "clientRef", UUID.randomUUID().toString(), "registerId", registerId,
                "lines", java.util.List.of(java.util.Map.of("productId", cocaId, "quantity", 1)),
                "payments", java.util.List.of(java.util.Map.of("paymentMethodId", cashId, "amount", 5, "tendered", 5))), 200));
        String reference = venteCourte.get("ticketNumber").asText();
        String affiche = venteCourte.get("ticketDisplay").asText();
        assertThat(reference).contains(an).endsWith("0501");   // la référence garde tout
        assertThat(affiche).isEqualTo("501");                  // le papier ne garde que le compteur

        // Le ticket imprimé porte l'affichage, pas la référence.
        JsonNode jobs = json(mvc.perform(get("/api/orders/" + venteCourte.get("id").asLong() + "/print-jobs")
                .header("Authorization", "Bearer " + admin)).andExpect(status().isOk()).andReturn());
        String papier = jobs.get(0).get("content").asText();
        // Le papier porte EXACTEMENT le numero demande, sans << N° >> ajoute d'office :
        // ce prefixe faisait doublon des que l'exploitant en mettait un dans son format.
        // La ligne est centree, d'ou le trim ; le marqueur de tete est celui du gras.
        String ligneNumero = papier.lines().filter(l -> !l.isEmpty() && l.charAt(0) == '\u0001')
                .map(l -> l.substring(1).trim()).findFirst().orElse("");
        assertThat(ligneNumero).isEqualTo(affiche);
        assertThat(papier).doesNotContain(reference).doesNotContain("N°");

        // Et on retrouve la vente en tapant ce qui est écrit sur le papier.
        JsonNode trouve = json(mvc.perform(get("/api/orders").param("ticket", affiche)
                .header("Authorization", "Bearer " + admin)).andExpect(status().isOk()).andReturn());
        assertThat(trouve.get("content").get(0).get("ticketNumber").asText()).isEqualTo(reference);

        // Un affichage sans compteur serait le même sur tous les tickets : refusé.
        mvc.perform(put("/api/ticket-numbering").header("Authorization", "Bearer " + admin)
                .contentType(MediaType.APPLICATION_JSON).content("{\"displayPattern\":\"TICKET\"}"))
                .andExpect(status().isBadRequest());

        postJson("/api/pos/session/" + sessionDuJour + "/close", cashierToken,
                java.util.Map.of("countedCash", 15), 200);
        putJson("/api/ticket-numbering", admin, java.util.Map.of(
                "pattern", "{POS}-{YYYY}-{SEQ:6}", "resetPeriod", "YEARLY",
                "perPos", true, "perRegister", false, "displayPattern", ""), 200);
    }

    /**
     * Reproduit le scénario réel : import d'une carte en mode « remplacer », qui ne peut que
     * désactiver les produits déjà vendus, puis nettoyage définitif. Vérifie que sans remise à
     * zéro des ventes rien n'est supprimé (et que l'utilisateur est averti), et qu'avec elle il
     * ne reste que le catalogue actif. Dernier test : il vide volontairement la base.
     */
    /**
     * Le stock des pâtes, de bout en bout.
     *
     * Ce qui s'épuise dans un fast-food à mlewi n'est pas un article mais une PÂTE : la
     * même pâte normale sert quarante sandwichs. Le compteur se pose donc sur la valeur de
     * variante, et « Double Normale » n'a pas de compteur — elle consomme deux pâtes
     * normales, la même pâte au frigo comptée deux fois.
     *
     * Le test tient les promesses qui, prises séparément, se contredisent facilement :
     * une double retire deux, une pénurie refuse la vente EN ENTIER (ni ticket, ni
     * numéro), une annulation rend la pâte, et une casse ne peut pas creuser un trou.
     */
    @Test @Order(8) void stockDesPatesParVariante() throws Exception {
        String admin = json(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"admin\",\"password\":\"admin123\"}")).andExpect(status().isOk()).andReturn()).get("token").asText();

        // ---- le paramétrage : trois compteurs, trois emprunteuses
        JsonNode axes = json(mvc.perform(get("/api/variants").header("Authorization", "Bearer " + admin)).andExpect(status().isOk()).andReturn());
        JsonNode pate = null; for (JsonNode a : axes) if (a.get("name").asText().equals("Pâte")) pate = a;
        assertThat(pate).as("l'axe Pâte du jeu de démonstration").isNotNull();
        long axeId = pate.get("id").asLong();
        List<Map<String, Object>> valeurs = new java.util.ArrayList<>();
        Map<String, Long> ids = new java.util.LinkedHashMap<>();
        for (JsonNode v : pate.get("values")) {
            ids.put(v.get("name").asText(), v.get("id").asLong());
            valeurs.add(new java.util.LinkedHashMap<>(Map.of("id", v.get("id").asLong(), "name", v.get("name").asText(),
                    "active", true, "stockManaged", true, "stockStep", 1)));
        }
        for (Map.Entry<String, Long> e : new java.util.LinkedHashMap<>(ids).entrySet()) {
            Map<String, Object> d = new java.util.LinkedHashMap<>();
            d.put("name", "Double " + e.getKey()); d.put("active", true);
            d.put("stockManaged", false); d.put("stockStep", 2); d.put("stockSourceId", e.getValue());
            valeurs.add(d);
        }
        Map<String, Object> corps = new java.util.LinkedHashMap<>(Map.of("name", "Pâte", "namePosition", "SUFFIX", "active", true, "values", valeurs));
        JsonNode enregistre = json(putJson("/api/variants/" + axeId, admin, corps, 200));
        long normale = ids.get("Normale"), doubleNormale = 0;
        for (JsonNode v : enregistre.get("values")) if (v.get("name").asText().equals("Double Normale")) {
            doubleNormale = v.get("id").asLong();
            assertThat(v.get("stockManaged").asBoolean()).isFalse();
            assertThat(v.get("stockSourceId").asLong()).isEqualTo(normale);
            assertThat(v.get("stockStep").decimalValue()).isEqualByComparingTo("2");
        }
        assertThat(doubleNormale).isPositive();

        // Un réglage qui retirerait deux fois la même pâte est refusé à l'enregistrement.
        List<Map<String, Object>> fautif = new java.util.ArrayList<>(valeurs);
        Map<String, Object> deuxFois = new java.util.LinkedHashMap<>(fautif.get(fautif.size() - 1));
        deuxFois.put("stockManaged", true);
        fautif.set(fautif.size() - 1, deuxFois);
        Map<String, Object> corpsFautif = new java.util.LinkedHashMap<>(corps);
        corpsFautif.put("values", fautif);
        putJson("/api/variants/" + axeId, admin, corpsFautif, 400);

        // ---- un article décliné sur les six pâtes
        JsonNode cat = json(mvc.perform(get("/api/pos/catalog").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        long produit = cat.get("products").get(0).get("id").asLong();
        JsonNode fiche = json(mvc.perform(get("/api/products/" + produit).header("Authorization", "Bearer " + admin)).andExpect(status().isOk()).andReturn());
        Map<String, Object> maj = om.convertValue(fiche, new TypeReference<>() {});
        maj.put("variantId", axeId); maj.put("askVariant", true); maj.put("defaultVariantValueId", normale);
        List<Map<String, Object>> prix = new java.util.ArrayList<>();
        for (JsonNode v : enregistre.get("values")) prix.add(Map.of("variantValueId", v.get("id").asLong(), "price", 5));
        maj.put("variantPrices", prix);
        putJson("/api/products/" + produit, admin, maj, 200);

        // ---- une caisse ouverte, et trois pâtes normales en stock
        // Le caissier a peut-etre encore sa caisse d'un test precedent. Une session sans
        // corps revient en noeud ABSENT et non en noeud nul : les deux valent << aucune >>.
        JsonNode courante = json(mvc.perform(get("/api/pos/session").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
        if (courante == null || !courante.has("registerId")) {
            JsonNode regs = json(mvc.perform(get("/api/pos/registers").header("Authorization", "Bearer " + cashierToken)).andExpect(status().isOk()).andReturn());
            JsonNode libre = null; for (JsonNode r : regs) if (r.get("openSession").isNull()) libre = r;
            assertThat(libre).as("une caisse libre").isNotNull();
            courante = json(postJson("/api/pos/session/open", cashierToken, Map.of("registerId", libre.get("id").asLong(), "openingFloat", 0), 200));
        }
        long caisse = courante.get("registerId").asLong();
        JsonNode etat = json(postJson("/api/pos/stock/entry", cashierToken, Map.of("variantValueId", normale, "quantity", 3), 200));
        assertThat(reste(etat, normale)).isEqualByComparingTo("3.000");
        // Ce qui tire sur la pâte est dit tel quel : sinon le compteur descend de deux
        // d'un coup sans que personne ne comprenne pourquoi.
        for (JsonNode l : etat.get("lines")) if (l.get("variantValueId").asLong() == normale)
            assertThat(l.get("borrowers").toString()).contains("Double Normale x2");

        // Le back-office lit le meme compteur sans caisse ouverte : c'est la que le gerant
        // regle le suivi, et un reglage sans chiffre en face ne se verifie pas.
        JsonNode compteurs = json(mvc.perform(get("/api/variants/stock").header("Authorization", "Bearer " + admin)).andExpect(status().isOk()).andReturn());
        JsonNode compteurNormale = null;
        for (JsonNode c : compteurs) if (c.get("variantValueId").asLong() == normale) compteurNormale = c;
        assertThat(compteurNormale).as("le compteur vu du back-office").isNotNull();
        assertThat(compteurNormale.get("quantity").decimalValue()).isEqualByComparingTo("3.000");
        assertThat(compteurNormale.get("pointOfSaleName").asText()).isNotBlank();

        // ---- une double retire deux
        long cash = cashId;
        JsonNode vente = json(postJson("/api/pos/checkout", cashierToken, venteDe(caisse, produit, doubleNormale, 1, cash, 5), 200));
        assertThat(reste(json(mvc.perform(get("/api/pos/stock").header("Authorization", "Bearer " + cashierToken)).andReturn()), normale))
                .as("« Double Normale » consomme deux pâtes").isEqualByComparingTo("1.000");

        // ---- la pénurie refuse la vente EN ENTIER
        long avant = orderCount(admin);
        postJson("/api/pos/checkout", cashierToken, venteDe(caisse, produit, normale, 2, cash, 10), 400);
        assertThat(orderCount(admin)).as("ni ticket ni numéro : la vente entière est refusée").isEqualTo(avant);
        assertThat(reste(json(mvc.perform(get("/api/pos/stock").header("Authorization", "Bearer " + cashierToken)).andReturn()), normale))
                .isEqualByComparingTo("1.000");

        // ---- l'annulation rend la pâte, le remboursement non (voir OrderService)
        postJson("/api/orders/" + vente.get("id").asLong() + "/cancel", managerToken, Map.of("reason", "Erreur de saisie"), 200);
        assertThat(reste(json(mvc.perform(get("/api/pos/stock").header("Authorization", "Bearer " + cashierToken)).andReturn()), normale))
                .as("le sandwich n'a pas été fait : la pâte revient").isEqualByComparingTo("3.000");

        // ---- la casse ne peut pas creuser un trou
        JsonNode apresCasse = json(postJson("/api/pos/stock/waste", cashierToken, Map.of("variantValueId", normale, "quantity", 3, "comment", "pâtes déchirées"), 200));
        assertThat(reste(apresCasse, normale)).isEqualByComparingTo("0.000");
        postJson("/api/pos/stock/waste", cashierToken, Map.of("variantValueId", normale, "quantity", 1), 400);
        // Le mouvement porte le motif : un stock qui descend sans vente est exactement ce
        // qu'on cherchera à comprendre le soir.
        assertThat(apresCasse.get("movements").toString()).contains("pâtes déchirées").contains("CASSE");

        // La caisse ouverte pour ce scenario est refermee : la purge du test suivant la
        // refuserait, et une caisse laissee ouverte par un test en fait echouer un autre
        // pour une raison qui n'a rien a voir avec ce qu'il verifie.
        postJson("/api/pos/session/" + courante.get("id").asLong() + "/close", cashierToken, Map.of("countedCash", 0), 200);
    }

    private Map<String, Object> venteDe(long registerId, long produit, long valeur, int qte, long moyen, int montant) {
        return Map.of("clientRef", UUID.randomUUID().toString(), "registerId", registerId, "serviceMode", "TAKEAWAY",
                "lines", List.of(Map.of("productId", produit, "quantity", qte, "variantValueId", valeur)),
                "payments", List.of(Map.of("paymentMethodId", moyen, "amount", montant)));
    }

    private java.math.BigDecimal reste(JsonNode etat, long valeurId) {
        for (JsonNode l : etat.get("lines")) if (l.get("variantValueId").asLong() == valeurId) return l.get("quantity").decimalValue();
        throw new AssertionError("valeur absente de l'état du stock : " + valeurId);
    }

    private long orderCount(String token) throws Exception {
        return json(mvc.perform(get("/api/orders").param("size", "1").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andReturn()).get("total").asLong();
    }

    @Test @Order(9) void purgeRemovesInactiveCatalogOnlyWithSalesReset() throws Exception {
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
