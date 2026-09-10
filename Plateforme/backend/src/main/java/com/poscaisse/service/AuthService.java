package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.Enums;
import com.poscaisse.domain.RegisterSession;
import com.poscaisse.domain.User;
import com.poscaisse.dto.AuthDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.SessionRepo;
import com.poscaisse.repository.UserRepo;
import com.poscaisse.security.AntiForceBrute;
import com.poscaisse.security.CurrentUser;
import com.poscaisse.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service @RequiredArgsConstructor
public class AuthService {
    private final UserRepo userRepo;
    private final SessionRepo sessionRepo;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final AuditService audit;
    private final CurrentUser currentUser;
    private final AntiForceBrute antiForce;
    /*
        L'adresse d'ou vient l'essai. Servlet-scoped : Spring injecte un mandataire, et
        chaque appel lit sa propre requete - il n'y a pas de melange entre deux caissiers.
    */
    private final jakarta.servlet.http.HttpServletRequest requete;

    @Transactional(readOnly = true)
    public List<UserTile> userTiles() {
        return userRepo.findByActiveTrueOrderByFullNameAsc().stream().filter(u -> u.getPinHash() != null).map(Mappers::userTile).toList();
    }

    @Transactional
    public AuthResponse loginWithPin(PinLoginRequest req) {
        String pin = req.pin().trim();
        // Quatre chiffres se devinent en dix mille essais : sans ce garde-fou, la caisse
        // s'ouvre toute seule en quelques secondes.
        String cle = "pin:" + adresse() + ":" + (req.userId() == null ? "*" : req.userId());
        antiForce.verifier(cle);
        if (pin.length() < 4 || pin.length() > 8 || !pin.chars().allMatch(Character::isDigit)) {
            antiForce.echec(cle);
            throw new BusinessException(HttpStatus.UNAUTHORIZED, "BAD_PIN", "PIN incorrect.");
        }
        Optional<User> match;
        if (req.userId() != null) {
            match = userRepo.findById(req.userId()).filter(u -> u.isActive() && u.getPinHash() != null && encoder.matches(pin, u.getPinHash()));
        } else {
            match = userRepo.findByActiveTrueAndPinHashIsNotNull().stream().filter(u -> encoder.matches(pin, u.getPinHash())).findFirst();
        }
        User user = match.orElseThrow(() -> {
            antiForce.echec(cle);
            audit.logAs(req.userId(), null, "LOGIN_FAILED", "User", req.userId(), "PIN incorrect");
            return new BusinessException(HttpStatus.UNAUTHORIZED, "BAD_PIN", "PIN incorrect.");
        });
        antiForce.succes(cle);
        return issue(user, "PIN");
    }

    @Transactional
    public AuthResponse loginWithPassword(LoginRequest req) {
        String identifiant = req.username().trim();
        /*
            Deux compteurs, et c'est voulu : l'un par adresse, l'autre par identifiant.
            Le premier arrete la machine qui essaie mille mots de passe depuis un poste ;
            le second arrete l'attaque repartie sur mille adresses contre le compte
            << admin >>, que le premier ne verrait jamais.
        */
        String parAdresse = "mdp:" + adresse();
        String parCompte = "mdp-compte:" + identifiant.toLowerCase();
        antiForce.verifier(parAdresse);
        antiForce.verifier(parCompte);
        User user = userRepo.findByUsernameIgnoreCase(identifiant)
                .filter(u -> u.isActive() && u.getPasswordHash() != null && encoder.matches(req.password(), u.getPasswordHash()))
                .orElseThrow(() -> {
                    antiForce.echec(parAdresse);
                    antiForce.echec(parCompte);
                    audit.logAs(null, identifiant, "LOGIN_FAILED", "User", null, "Mot de passe incorrect");
                    return new BusinessException(HttpStatus.UNAUTHORIZED, "BAD_CREDENTIALS", "Identifiant ou mot de passe incorrect.");
                });
        antiForce.succes(parAdresse);
        antiForce.succes(parCompte);
        return issue(user, "PASSWORD");
    }

    /**
     * L'adresse de celui qui essaie.
     *
     * Derriere un proxy, l'adresse vue par l'application est celle du proxy : tous les
     * postes se confondraient en une seule. On lit donc X-Forwarded-For quand il est la -
     * en ne gardant que la PREMIERE adresse, la seule que le proxy ait ecrite lui-meme,
     * les suivantes pouvant etre inventees par l'appelant.
     */
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

    private AuthResponse issue(User user, String method) {
        user.setLastLoginAt(OffsetDateTime.now());
        userRepo.save(user);
        audit.logAs(user.getId(), user.getUsername(), "LOGIN", "User", user.getId(), "Connexion par " + method);
        String token = jwt.generate(user.getId(), user.getUsername(), Map.of("role", user.getRole().getCode(), "name", user.getFullName()));
        return new AuthResponse(token, Mappers.currentUser(user), Mappers.sessionInfo(openSessionFor(user)));
    }

    @Transactional(readOnly = true)
    public AuthResponse me() {
        User u = currentUser.entity();
        return new AuthResponse(null, Mappers.currentUser(u), Mappers.sessionInfo(openSessionFor(u)));
    }

    private RegisterSession openSessionFor(User u) {
        return sessionRepo.findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(u.getId(), Enums.SessionStatus.OPEN).orElse(null);
    }

    @Transactional
    public void changePin(ChangePinRequest req) {
        User u = currentUser.entity();
        if (u.getPinHash() == null || !encoder.matches(req.currentPin(), u.getPinHash())) throw new BusinessException("PIN actuel incorrect.");
        validatePin(req.newPin());
        u.setPinHash(encoder.encode(req.newPin()));
        userRepo.save(u);
        audit.log("PIN_CHANGED", "User", u.getId(), null);
    }

    public static void validatePin(String pin) {
        if (pin == null || pin.length() < 4 || pin.length() > 8 || !pin.chars().allMatch(Character::isDigit))
            throw new BusinessException("Le PIN doit contenir entre 4 et 8 chiffres.");
    }

    @Transactional
    public void logout() {
        try { audit.log("LOGOUT", "User", currentUser.id(), null); } catch (Exception ignored) {}
    }
}
