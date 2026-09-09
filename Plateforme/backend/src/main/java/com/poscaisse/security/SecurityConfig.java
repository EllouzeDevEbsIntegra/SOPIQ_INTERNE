package com.poscaisse.security;

import com.poscaisse.exception.ApiError;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
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

import java.util.ArrayList;
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
     *
     * L'ADRESSE QUI SERT L'ECRAN EST TOUJOURS AUTORISEE, sans etre configuree nulle part.
     * Derriere nginx, la caisse se voit elle-meme sur http://127.0.0.1:8122 alors que le
     * navigateur l'appelle sur https://demo-cafe.pos.ebs-integra.com : Spring compare les
     * deux, ne les reconnait pas identiques, et rejette une requete pourtant de meme
     * origine - << Invalid CORS request >>, ecran blanc, sur une caisse qui vient de
     * demarrer normalement. Chaque nouvelle adresse - un client, une demonstration -
     * demanderait sinon sa ligne de configuration, et l'oubli ne se voit qu'a l'ouverture.
     *
     * Ce n'est pas un relachement : on n'autorise l'origine QUE si elle est exactement
     * celle a laquelle la requete s'adresse. Une page hebergee ailleurs ne peut pas remplir
     * cette condition - c'est la definition meme de la meme origine.
     *
     * La liste configuree reste necessaire pour ce qui vient d'AILLEURS : l'interface de
     * developpement sur localhost:5173, par exemple.
     */
    @Bean
    public CorsConfigurationSource corsSource() {
        List<String> configurees = Arrays.stream(corsOrigins.split(",")).map(String::trim).filter(o -> !o.isEmpty()).toList();
        if (configurees.stream().anyMatch(o -> o.equals("*")))
            throw new IllegalStateException("POSCAISSE_CORS_ORIGINS = « * » avec des identifiants : "
                    + "nommez les adresses autorisées (par exemple https://caisse.mondomaine.tn).");

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
     * (X-Forwarded-Proto) et l'hote demande. Sans nginx - en developpement, ou sur une
     * caisse posee directement sur le reseau du magasin - on retombe sur ce que voit le
     * serveur lui-meme.
     */
    private static String laNotre(HttpServletRequest requete) {
        String hote = requete.getHeader("Host");
        if (hote == null || hote.isBlank()) return null;
        String protocole = requete.getHeader("X-Forwarded-Proto");
        if (protocole == null || protocole.isBlank()) protocole = requete.getScheme();
        return protocole + "://" + hote;
    }
}
