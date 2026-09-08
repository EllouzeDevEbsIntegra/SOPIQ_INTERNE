package com.poscaisse.plateforme.security;

import com.poscaisse.plateforme.domain.Enums;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/** Lit le jeton, pose qui parle. Un jeton illisible ne fait pas echouer la requete : il ne pose rien. */
@Component @RequiredArgsConstructor
public class JwtFiltre extends OncePerRequestFilter {
    private final JwtService jwt;

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String entete = req.getHeader("Authorization");
        if (entete != null && entete.startsWith("Bearer ")) {
            try {
                Claims c = jwt.lire(entete.substring(7));
                Enums.Role role = Enums.Role.valueOf(c.get("role", String.class));
                UtilisateurCourant.Principal p = new UtilisateurCourant.Principal(
                        Long.valueOf(c.getSubject()), c.get("username", String.class), role);
                var auth = new UsernamePasswordAuthenticationToken(p, null,
                        List.of(new SimpleGrantedAuthority("ROLE_" + role.name())));
                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (Exception e) {
                // Jeton expire ou trafique : on ne pose personne, la suite repondra 401.
                SecurityContextHolder.clearContext();
            }
        }
        chain.doFilter(req, res);
    }
}
