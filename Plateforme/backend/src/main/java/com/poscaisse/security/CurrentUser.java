package com.poscaisse.security;

import com.poscaisse.domain.Permission;
import com.poscaisse.domain.User;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.UserRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component @RequiredArgsConstructor
public class CurrentUser {
    private final UserRepo userRepo;

    public UserPrincipal principal() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || !(a.getPrincipal() instanceof UserPrincipal p)) throw new BusinessException(org.springframework.http.HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "Authentification requise.");
        return p;
    }

    public Long id() { return principal().getId(); }

    public User entity() { return userRepo.findById(id()).orElseThrow(() -> BusinessException.notFound("Utilisateur")); }

    public boolean has(Permission p) { return principal().has(p); }

    /**
     * La meme question, mais qui ne fait pas d'histoire quand personne n'est connecte.
     *
     * Certains calculs tournent aussi bien pour un utilisateur que pour une tache de fond
     * - une cloture programmee, par exemple. Leur faire porter un try/catch pour savoir
     * s'ils ont le droit d'afficher une ligne serait absurde : ici, pas d'utilisateur vaut
     * pas de droit.
     */
    public boolean peut(Permission p) {
        try { return has(p); } catch (RuntimeException e) { return false; }
    }

    public void require(Permission p, String message) {
        if (!has(p)) throw BusinessException.forbidden(message);
    }
}
