package com.poscaisse.plateforme.security;

import com.poscaisse.plateforme.domain.EditeurUser;
import com.poscaisse.plateforme.domain.Enums;
import com.poscaisse.plateforme.repository.EditeurUserRepo;
import com.poscaisse.plateforme.service.ErreurMetier;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Optional;

/** Qui parle, et ce qu'il a le droit de faire. */
@Component @RequiredArgsConstructor
public class UtilisateurCourant {
    private final EditeurUserRepo users;

    public Optional<EditeurUser> peutEtre() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || !(a.getPrincipal() instanceof Principal p)) return Optional.empty();
        return users.findById(p.id());
    }

    public EditeurUser exigeConnecte() {
        return peutEtre().orElseThrow(() -> new ErreurMetier(org.springframework.http.HttpStatus.UNAUTHORIZED,
                "NON_CONNECTE", "Authentification requise."));
    }

    /**
     * Le droit, ou un refus qui dit ce qui manque.
     *
     * << Vous n'avez pas la permission >> est un message pour developpeur. Ici on nomme le
     * role qu'il faudrait : c'est la seule facon que l'utilisateur sache a qui demander.
     */
    public void exige(Enums.Droit d) {
        EditeurUser u = exigeConnecte();
        if (!u.getRole().peut(d))
            throw ErreurMetier.interdit("Action réservée : votre rôle « " + u.getRole()
                    + " » ne permet pas « " + libelle(d) + " ». Demandez à un administrateur.");
    }

    private static String libelle(Enums.Droit d) {
        return switch (d) {
            case LIRE -> "consulter";
            case GERER_CLIENTS -> "gérer les clients et les abonnements";
            case ENCAISSER -> "saisir les règlements";
            case UTILISATEURS -> "gérer les comptes";
        };
    }

    /** Ce que le jeton porte : de quoi eviter une requete a chaque appel. */
    public record Principal(Long id, String username, Enums.Role role) {}
}
