package com.poscaisse.plateforme.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * La securite du back-office editeur.
 *
 * Deux endpoints publics, et seulement deux : la connexion, et la verification de licence
 * qu'appellent les caisses des clients. Tout le reste exige un jeton - ce back-office
 * porte les contrats de tout le parc.
 */
@Configuration @RequiredArgsConstructor
public class ConfigSecurite {
    private final JwtFiltre jwtFiltre;
    private final ObjectMapper json;
    @Value("${plateforme.cors-origins}") private String corsOrigins;

    @Bean
    public PasswordEncoder encodeur() { return new BCryptPasswordEncoder(10); }

    @Bean
    public SecurityFilterChain chaine(HttpSecurity http) throws Exception {
        http.csrf(c -> c.disable())
            .cors(c -> c.configurationSource(cors()))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req, res, ex) -> ecrire(res, 401, "NON_CONNECTE", "Authentification requise."))
                .accessDeniedHandler((req, res, ex) -> ecrire(res, 403, "INTERDIT", "Action non autorisée.")))
            .authorizeHttpRequests(a -> a
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/auth/connexion", "/api/licences/verifier", "/actuator/health").permitAll()
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll())
            .addFilterBefore(jwtFiltre, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    private void ecrire(jakarta.servlet.http.HttpServletResponse res, int statut, String code, String message)
            throws java.io.IOException {
        res.setStatus(statut);
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(json.writeValueAsString(Map.of("status", statut, "code", code, "message", message)));
    }

    /**
     * Qui a le droit d'appeler cette API depuis un navigateur.
     *
     * SA PROPRE ADRESSE EST TOUJOURS AUTORISEE. Le back-office sert lui-meme son ecran :
     * la page et l'API sont a la meme adresse, et une requete d'une page vers sa propre
     * origine n'est pas une requete distante - il n'y a rien a proteger contre soi-meme.
     * Sans cette regle, une installation ou personne n'a pense a remplir
     * PLATEFORME_CORS_ORIGINS s'ouvre sur un ecran de connexion qui refuse de connecter,
     * avec pour seul indice un message JSON illisible. C'est arrive au premier
     * deploiement, et cela reviendrait a chaque nouveau serveur.
     *
     * Ce n'est pas un relachement : on n'autorise l'origine QUE si elle est exactement
     * celle a laquelle la requete s'adresse. Une page hebergee ailleurs ne peut pas
     * remplir cette condition - c'est la definition meme de la meme origine.
     *
     * La liste configuree reste necessaire pour ce qui vient d'AILLEURS : l'interface de
     * developpement sur localhost:5173, ou un jour un portail client sur un autre domaine.
     *
     * Le joker avec identifiants est refuse, ici comme dans la caisse, et pour la meme
     * raison : << * >> avec des identifiants laisse n'importe quelle page piegee agir au
     * nom de l'utilisateur connecte.
     */
    @Bean
    public CorsConfigurationSource cors() {
        List<String> configurees = Arrays.stream(corsOrigins.split(",")).map(String::trim).filter(o -> !o.isEmpty()).toList();
        if (configurees.contains("*"))
            throw new IllegalStateException("PLATEFORME_CORS_ORIGINS = « * » avec des identifiants : nommez les adresses.");

        return requete -> {
            CorsConfiguration cfg = new CorsConfiguration();
            cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
            cfg.setAllowedHeaders(List.of("*"));
            cfg.setAllowCredentials(true);

            List<String> permises = new ArrayList<>(configurees);
            String origine = requete.getHeader("Origin");
            if (origine != null && origine.equals(laNotre(requete))) permises.add(origine);
            cfg.setAllowedOriginPatterns(permises);
            return cfg;
        };
    }

    /**
     * L'adresse a laquelle CETTE requete s'adresse, telle que le navigateur l'a ecrite.
     *
     * Reconstruite depuis les en-tetes que nginx pose devant nous : le protocole d'origine
     * (X-Forwarded-Proto) et l'hote demande. Sans nginx - en developpement - on retombe sur
     * ce que voit le serveur lui-meme.
     */
    private static String laNotre(HttpServletRequest requete) {
        String hote = requete.getHeader("Host");
        if (hote == null || hote.isBlank()) return null;
        String protocole = requete.getHeader("X-Forwarded-Proto");
        if (protocole == null || protocole.isBlank()) protocole = requete.getScheme();
        return protocole + "://" + hote;
    }
}
