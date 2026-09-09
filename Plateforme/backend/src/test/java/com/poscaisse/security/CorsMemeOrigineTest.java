package com.poscaisse.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.cors.CorsConfiguration;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'ADRESSE QUI SERT L'ECRAN DOIT S'AUTORISER ELLE-MEME.
 *
 * Ce test existe parce que le defaut est passe DEUX FOIS en production, sur les deux
 * applications, et qu'aucun test ne le voyait : en developpement le navigateur appelle
 * la caisse sur la meme adresse que celle qu'elle croit occuper, et tout marche. Derriere
 * nginx, plus du tout - la caisse se voit sur http://127.0.0.1:8122 quand le navigateur
 * l'appelle sur https://demo-cafe.pos.ebs-integra.com. Spring compare, ne reconnait pas,
 * et rend << Invalid CORS request >> : ecran blanc sur une caisse qui vient de demarrer
 * normalement, et rien dans le journal qui ressemble a une erreur.
 *
 * Le troisieme scenario est le plus important des trois : il verifie qu'ouvrir sa propre
 * origine n'ouvre pas celle des autres. Une page hebergee ailleurs ne peut pas se faire
 * passer pour la notre - l'en-tete Origin qu'elle envoie est le sien, et il ne peut pas
 * valoir a la fois son adresse et la notre.
 */
class CorsMemeOrigineTest {

    private CorsConfiguration pour(String origine, String hote, String protocoleTransmis) {
        SecurityConfig config = new SecurityConfig(null, new ObjectMapper());
        ReflectionTestUtils.setField(config, "corsOrigins", "http://localhost:5173");

        MockHttpServletRequest requete = new MockHttpServletRequest("GET", "/api/products");
        if (origine != null) requete.addHeader("Origin", origine);
        requete.addHeader("Host", hote);
        if (protocoleTransmis != null) requete.addHeader("X-Forwarded-Proto", protocoleTransmis);
        return config.corsSource().getCorsConfiguration(requete);
    }

    @Test
    @DisplayName("derrière nginx, la caisse autorise l'adresse par laquelle on l'appelle")
    void memeOrigineDerriereNginx() {
        CorsConfiguration cfg = pour("https://demo-cafe.pos.ebs-integra.com",
                "demo-cafe.pos.ebs-integra.com", "https");
        assertThat(cfg.getAllowedOriginPatterns())
                .contains("https://demo-cafe.pos.ebs-integra.com");
    }

    @Test
    @DisplayName("les adresses configurées restent autorisées")
    void listeConfiguree() {
        CorsConfiguration cfg = pour("http://localhost:5173", "localhost:8080", null);
        assertThat(cfg.getAllowedOriginPatterns()).contains("http://localhost:5173");
    }

    @Test
    @DisplayName("une page hébergée ailleurs reste refusée")
    void origineEtrangere() {
        CorsConfiguration cfg = pour("https://site-pirate.example",
                "demo-cafe.pos.ebs-integra.com", "https");
        assertThat(cfg.getAllowedOriginPatterns())
                .containsExactly("http://localhost:5173");
    }

    @Test
    @DisplayName("sans nginx devant, la caisse se reconnaît sur son propre protocole")
    void sansProxy() {
        CorsConfiguration cfg = pour("http://caisse.local:8080", "caisse.local:8080", null);
        assertThat(cfg.getAllowedOriginPatterns()).contains("http://caisse.local:8080");
    }
}
