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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

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

    /** Le joker avec identifiants est refuse, ici comme dans la caisse, et pour la meme raison. */
    @Bean
    public CorsConfigurationSource cors() {
        CorsConfiguration cfg = new CorsConfiguration();
        List<String> origines = Arrays.stream(corsOrigins.split(",")).map(String::trim).filter(o -> !o.isEmpty()).toList();
        if (origines.contains("*"))
            throw new IllegalStateException("PLATEFORME_CORS_ORIGINS = « * » avec des identifiants : nommez les adresses.");
        cfg.setAllowedOriginPatterns(origines);
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("*"));
        cfg.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", cfg);
        return src;
    }
}
