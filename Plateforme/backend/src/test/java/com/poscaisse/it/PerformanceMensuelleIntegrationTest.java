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

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@EnabledIfEnvironmentVariable(named = "POSCAISSE_IT", matches = "true")
class PerformanceMensuelleIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper om;
    @Autowired JdbcTemplate jdbc;

    @DynamicPropertySource
    static void baseNeuve(DynamicPropertyRegistry r) {
        BaseDeTest.neuve(r, "poscaisse_audit_performance_mois");
    }

    @Test
    void troisMilleVentesGardentRapportsEtCloturesSousUneSecondeAuP95() throws Exception {
        long societe = jdbc.queryForObject("select id from company limit 1", Long.class);
        long point = jdbc.queryForObject("select id from point_of_sale order by id limit 1", Long.class);
        long caisse = jdbc.queryForObject("select id from register order by id limit 1", Long.class);
        long utilisateur = jdbc.queryForObject("select id from app_user where username='admin'", Long.class);
        long produit = jdbc.queryForObject("select id from product order by id limit 1", Long.class);
        long categorie = jdbc.queryForObject("select category_id from product where id=?", Long.class, produit);
        long paiement = jdbc.queryForObject("select id from payment_method where kind='CASH' order by id limit 1", Long.class);

        jdbc.update("""
                insert into register_session(register_id, opened_by, closed_by, status, opened_at, closed_at,
                  opening_float, cash_sales, card_sales, other_sales, cash_refunds, cash_in, cash_out,
                  expected_cash, counted_cash, cash_difference, tickets_count, revenue)
                select ?, ?, ?, 'CLOSED',
                  ((current_date - g) + time '08:00') at time zone 'Africa/Tunis',
                  ((current_date - g) + time '18:00') at time zone 'Africa/Tunis',
                  100, 1000, 0, 0, 0, 0, 0, 1100, 1100, 0, 100, 1000
                from generate_series(0, 29) g
                """, caisse, utilisateur, utilisateur);
        jdbc.update("""
                with sessions as (
                  select id, opened_at, row_number() over(order by opened_at desc) as jour
                  from register_session where closing_note is null
                )
                insert into sale_order(client_ref, ticket_number, company_id, point_of_sale_id, register_id,
                  session_id, cashier_id, service_mode, status, subtotal, total, paid_total, paid_at)
                select 'audit-mois-' || g, 'AUDIT-' || g, ?, ?, ?, s.id, ?, 'TAKEAWAY', 'PAID', 10, 10, 10,
                  s.opened_at + interval '1 hour' + ((g - 1) % 100) * interval '5 minutes'
                from generate_series(1, 3000) g
                join sessions s on s.jour = ((g - 1) / 100) + 1
                """, societe, point, caisse, utilisateur);
        jdbc.update("""
                insert into order_line(order_id, product_id, category_id, product_code, product_name,
                  quantity, original_unit_price, unit_price, line_total)
                select id, ?, ?, 'AUDIT', 'Article audit', 1, 10, 10, 10
                from sale_order where client_ref like 'audit-mois-%'
                """, produit, categorie);
        jdbc.update("""
                insert into payment(order_id, session_id, payment_method_id, amount, tendered)
                select id, session_id, ?, 10, 10 from sale_order where client_ref like 'audit-mois-%'
                """, paiement);

        String jeton = om.readTree(mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"admin\",\"password\":\"admin123\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).get("token").asText();
        LocalDate fin = LocalDate.now();
        LocalDate debut = fin.minusDays(29);
        String rapport = "/api/reports/dashboard?from=" + debut + "&to=" + fin;

        mvc.perform(get(rapport).header("Authorization", "Bearer " + jeton)).andExpect(status().isOk());
        List<Long> rapports = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            long t = System.nanoTime();
            mvc.perform(get(rapport).header("Authorization", "Bearer " + jeton)).andExpect(status().isOk());
            rapports.add((System.nanoTime() - t) / 1_000_000);
        }

        List<Long> clotures = new ArrayList<>();
        for (int i = 0; i < 30; i++) {
            LocalDate jour = debut.plusDays(i);
            String corps = "{\"pointOfSaleId\":" + point + ",\"businessDate\":\"" + jour
                    + "\",\"note\":\"Audit local\"}";
            long t = System.nanoTime();
            mvc.perform(post("/api/closures").header("Authorization", "Bearer " + jeton)
                            .contentType(MediaType.APPLICATION_JSON).content(corps))
                    .andExpect(status().isOk());
            clotures.add((System.nanoTime() - t) / 1_000_000);
        }

        long rapportMediane = percentile(rapports, .5), rapportP95 = percentile(rapports, .95);
        long clotureMediane = percentile(clotures, .5), clotureP95 = percentile(clotures, .95);
        System.out.printf("AUDIT_MOIS ventes=3000 rapport_mediane_ms=%d rapport_p95_ms=%d "
                        + "cloture_mediane_ms=%d cloture_p95_ms=%d%n",
                rapportMediane, rapportP95, clotureMediane, clotureP95);
        assertThat(rapportP95).isLessThan(1000);
        assertThat(clotureP95).isLessThan(1000);
    }

    private static long percentile(List<Long> valeurs, double rang) {
        List<Long> triees = new ArrayList<>(valeurs);
        Collections.sort(triees);
        return triees.get(Math.max(0, (int) Math.ceil(triees.size() * rang) - 1));
    }
}
