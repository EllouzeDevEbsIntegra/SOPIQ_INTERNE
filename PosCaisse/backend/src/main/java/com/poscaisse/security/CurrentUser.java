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

    public void require(Permission p, String message) {
        if (!has(p)) throw BusinessException.forbidden(message);
    }
}
