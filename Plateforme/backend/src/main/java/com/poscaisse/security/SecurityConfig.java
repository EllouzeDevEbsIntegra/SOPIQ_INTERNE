package com.poscaisse.security;

import com.poscaisse.exception.ApiError;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
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

@Configuration @EnableMethodSecurity @RequiredArgsConstructor
public class SecurityConfig {
    private final JwtAuthFilter jwtAuthFilter;
    private final ObjectMapper objectMapper;
    @Value("${poscaisse.cors-origins}") private String corsOrigins;

    /*
        Cout 10, la valeur de reference de BCrypt. A 8, un mot de passe vole se casse
        quatre fois plus vite ; l'ecart de temps a la connexion est de quelques dizaines
        de millisecondes, que personne ne voit. Les empreintes deja en base restent
        valides : chacune porte son propre cout.
    */
    @Bean
    public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(10); }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(c -> c.disable())
            .cors(c -> c.configurationSource(corsSource()))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req, res, ex) -> write(res, 401, "UNAUTHORIZED", "Authentification requise."))
                .accessDeniedHandler((req, res, ex) -> write(res, 403, "FORBIDDEN", "Vous n'avez pas la permission d'effectuer cette action.")))
            .authorizeHttpRequests(a -> a
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/auth/**", "/actuator/health", "/api/public/**").permitAll()
                .requestMatchers("/", "/index.html", "/assets/**", "/favicon.ico", "/favicon.svg").permitAll()
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll())
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    private void write(jakarta.servlet.http.HttpServletResponse res, int status, String code, String msg) throws java.io.IOException {
        res.setStatus(status);
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(objectMapper.writeValueAsString(ApiError.of(status, code, msg)));
    }

    /**
     * Qui a le droit d'appeler l'API depuis un navigateur.
     *
     * Le joker est refuse tant que les identifiants voyagent : << n'importe quel site >>
     * plus << avec les cookies et le jeton >>, c'est autoriser une page piegee a agir au
     * nom du caissier connecte. Le refus est net et nomme le reglage fautif - un demarrage
     * qui echoue en disant pourquoi vaut mieux qu'une caisse ouverte a tout le monde.
     */
    @Bean
    public CorsConfigurationSource corsSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        List<String> origines = Arrays.stream(corsOrigins.split(",")).map(String::trim).filter(o -> !o.isEmpty()).toList();
        if (origines.stream().anyMatch(o -> o.equals("*")))
            throw new IllegalStateException("POSCAISSE_CORS_ORIGINS = « * » avec des identifiants : "
                    + "nommez les adresses autorisées (par exemple https://caisse.mondomaine.tn).");
        cfg.setAllowedOriginPatterns(origines);
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("*"));
        cfg.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", cfg);
        return src;
    }
}
