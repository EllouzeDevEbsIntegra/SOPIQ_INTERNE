package com.poscaisse;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * L'authentification passe exclusivement par JWT (voir SecurityConfig / JwtAuthFilter) :
 * on exclut l'auto-configuration Spring Security qui créerait un utilisateur en mémoire
 * et afficherait un "generated security password" trompeur au démarrage.
 */
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
@EnableScheduling
public class PosCaisseApplication {
    public static void main(String[] args) {
        SpringApplication.run(PosCaisseApplication.class, args);
    }
}
