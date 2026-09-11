package com.poscaisse.plateforme.security;

import com.poscaisse.plateforme.domain.EditeurUser;
import com.poscaisse.plateforme.domain.Enums;
import com.poscaisse.plateforme.repository.EditeurUserRepo;
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
    private final EditeurUserRepo users;

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String entete = req.getHeader("Authorization");
        if (entete != null && entete.startsWith("Bearer ")) {
            try {
                Claims c = jwt.lire(entete.substring(7));
                Long id = Long.valueOf(c.getSubject());
                EditeurUser u = users.findById(id).orElse(null);
                if (u != null && u.isActive()) {
                    UtilisateurCourant.Principal p = new UtilisateurCourant.Principal(
                            u.getId(), u.getUsername(), u.getRole());
                    var auth = new UsernamePasswordAuthenticationToken(p, null,
                            List.of(new SimpleGrantedAuthority("ROLE_" + u.getRole().name())));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                } else {
                    SecurityContextHolder.clearContext();
                }
            } catch (Exception e) {
                // Jeton expire ou trafique : on ne pose personne, la suite repondra 401.
                SecurityContextHolder.clearContext();
            }
        }
        chain.doFilter(req, res);
    }
}
