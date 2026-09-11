package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.EditeurUser;
import com.poscaisse.plateforme.domain.Enums;
import com.poscaisse.plateforme.dto.Dtos.*;
import com.poscaisse.plateforme.repository.EditeurUserRepo;
import com.poscaisse.plateforme.security.AntiForceBrute;
import com.poscaisse.plateforme.security.JwtService;
import com.poscaisse.plateforme.security.UtilisateurCourant;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

/** La connexion au back-office, et les comptes de l'equipe. */
@Service @RequiredArgsConstructor
public class AuthService {
    private final EditeurUserRepo users;
    private final PasswordEncoder encodeur;
    private final JwtService jwt;
    private final AntiForceBrute antiForce;
    private final JournalService journal;
    private final UtilisateurCourant courant;
    private final HttpServletRequest requete;

    @Transactional
    public ConnexionReponse connexion(ConnexionRequest r) {
        String identifiant = r.username().trim();
        String parAdresse = "mdp:" + adresse();
        String parCompte = "compte:" + identifiant.toLowerCase();
        antiForce.verifier(parAdresse);
        antiForce.verifier(parCompte);

        EditeurUser u = users.findByUsernameIgnoreCase(identifiant)
                .filter(x -> x.isActive() && encodeur.matches(r.password(), x.getPasswordHash()))
                .orElseThrow(() -> {
                    antiForce.echec(parAdresse);
                    antiForce.echec(parCompte);
                    journal.ecrire("CONNEXION_REFUSEE", "EditeurUser", null, identifiant);
                    return new ErreurMetier(HttpStatus.UNAUTHORIZED, "IDENTIFIANTS",
                            "Identifiant ou mot de passe incorrect.");
                });
        antiForce.succes(parAdresse);
        antiForce.succes(parCompte);
        u.setLastLoginAt(OffsetDateTime.now());
        users.save(u);
        return new ConnexionReponse(jwt.pour(u), dto(u), jwt.dureeMinutes());
    }

    @Transactional(readOnly = true)
    public UtilisateurDto moi() { return dto(courant.exigeConnecte()); }

    @Transactional(readOnly = true)
    public List<UtilisateurDto> tous() {
        courant.exige(Enums.Droit.UTILISATEURS);
        return users.findAllByOrderByFullNameAsc().stream().map(AuthService::dto).toList();
    }

    @Transactional
    public UtilisateurDto enregistrer(Long id, UtilisateurRequest r) {
        courant.exige(Enums.Droit.UTILISATEURS);
        EditeurUser u = id == null ? new EditeurUser()
                : users.findById(id).orElseThrow(() -> ErreurMetier.introuvable("Utilisateur"));
        if (id == null && users.findByUsernameIgnoreCase(r.username().trim()).isPresent())
            throw new ErreurMetier("L'identifiant « " + r.username().trim() + " » est déjà pris.");
        u.setUsername(r.username().trim());
        u.setFullName(r.fullName().trim());
        u.setEmail(r.email());
        u.setRole(r.role());
        if (r.active() != null) u.setActive(r.active());
        if (r.password() != null && !r.password().isBlank()) {
            if (r.password().length() < 8)
                throw new ErreurMetier("Le mot de passe doit faire au moins 8 caractères.");
            u.setPasswordHash(encodeur.encode(r.password()));
        } else if (id == null) {
            throw new ErreurMetier("Un mot de passe est nécessaire pour créer un compte.");
        }
        u = users.save(u);
        journal.ecrire(id == null ? "UTILISATEUR_CREE" : "UTILISATEUR_MODIFIE", "EditeurUser", u.getId(), u.getUsername());
        return dto(u);
    }

    private String adresse() {
        String ip = requete.getRemoteAddr();
        if ("127.0.0.1".equals(ip) || "0:0:0:0:0:0:0:1".equals(ip) || "::1".equals(ip)) {
            String tete = requete.getHeader("X-Forwarded-For");
            if (tete != null && !tete.isBlank()) {
                String[] parties = tete.split(",");
                String derniere = parties[parties.length - 1].trim();
                if (!derniere.isEmpty()) return derniere;
            }
        }
        return ip == null ? "?" : ip;
    }

    static UtilisateurDto dto(EditeurUser u) {
        return new UtilisateurDto(u.getId(), u.getUsername(), u.getFullName(), u.getEmail(), u.getRole(),
                u.isActive(), u.getLastLoginAt());
    }
}
