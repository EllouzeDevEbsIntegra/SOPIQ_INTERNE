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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Le premier compte.
 *
 * Le premier secret est fourni par l'installateur. Aucun secret commun aux installations
 * ne doit ouvrir tous les contrats, ni etre recopie dans les journaux.
 */
@Configuration @RequiredArgsConstructor
public class Amorcage {
    private static final Logger log = LoggerFactory.getLogger(Amorcage.class);
    @Value("${plateforme.admin-password:}") private String motDePasseInitial;

    @Bean
    ApplicationRunner premierCompte(EditeurUserRepo users, PasswordEncoder encodeur) {
        return args -> {
            if (users.count() > 0) return;
            if (motDePasseInitial == null || motDePasseInitial.length() < 12 || motDePasseInitial.isBlank())
                throw new IllegalStateException("Premier démarrage : définissez PLATEFORME_ADMIN_PASSWORD "
                        + "avec un mot de passe d'au moins 12 caractères, puis redémarrez.");
            EditeurUser u = new EditeurUser();
            u.setUsername("admin");
            u.setFullName("Administrateur plateforme");
            u.setRole(Enums.Role.ADMIN);
            u.setPasswordHash(encodeur.encode(motDePasseInitial));
            users.save(u);
            log.info("Premier compte administrateur créé avec le secret fourni à l'installation.");
        };
    }
}
