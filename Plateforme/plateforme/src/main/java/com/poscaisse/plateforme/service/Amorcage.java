package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.EditeurUser;
import com.poscaisse.plateforme.domain.Enums;
import com.poscaisse.plateforme.repository.EditeurUserRepo;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Le premier compte.
 *
 * Un back-office sans compte ne s'ouvre pas ; on en cree donc un, une seule fois, et on
 * ECRIT DANS LE JOURNAL qu'il faut changer son mot de passe. Un mot de passe par defaut
 * qu'on oublie de changer est la porte d'entree la plus banale qui soit.
 */
@Configuration @RequiredArgsConstructor
public class Amorcage {
    private static final Logger log = LoggerFactory.getLogger(Amorcage.class);

    @Bean
    ApplicationRunner premierCompte(EditeurUserRepo users, PasswordEncoder encodeur) {
        return args -> {
            if (users.count() > 0) return;
            EditeurUser u = new EditeurUser();
            u.setUsername("admin");
            u.setFullName("Administrateur plateforme");
            u.setRole(Enums.Role.ADMIN);
            u.setPasswordHash(encodeur.encode("plateforme123"));
            users.save(u);
            log.warn("Premier compte créé : admin / plateforme123 — CHANGEZ CE MOT DE PASSE avant "
                   + "d'ouvrir ce back-office sur internet.");
        };
    }
}
