package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.Enums;
import com.poscaisse.domain.RegisterSession;
import com.poscaisse.domain.User;
import com.poscaisse.dto.AuthDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.SessionRepo;
import com.poscaisse.repository.UserRepo;
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

    @Transactional(readOnly = true)
    public List<UserTile> userTiles() {
        return userRepo.findByActiveTrueOrderByFullNameAsc().stream().filter(u -> u.getPinHash() != null).map(Mappers::userTile).toList();
    }

    @Transactional
    public AuthResponse loginWithPin(PinLoginRequest req) {
        String pin = req.pin().trim();
        if (pin.length() < 4 || pin.length() > 8 || !pin.chars().allMatch(Character::isDigit))
            throw new BusinessException(HttpStatus.UNAUTHORIZED, "BAD_PIN", "PIN incorrect.");
        Optional<User> match;
        if (req.userId() != null) {
            match = userRepo.findById(req.userId()).filter(u -> u.isActive() && u.getPinHash() != null && encoder.matches(pin, u.getPinHash()));
        } else {
            match = userRepo.findByActiveTrueAndPinHashIsNotNull().stream().filter(u -> encoder.matches(pin, u.getPinHash())).findFirst();
        }
        User user = match.orElseThrow(() -> {
            audit.logAs(req.userId(), null, "LOGIN_FAILED", "User", req.userId(), "PIN incorrect");
            return new BusinessException(HttpStatus.UNAUTHORIZED, "BAD_PIN", "PIN incorrect.");
        });
        return issue(user, "PIN");
    }

    @Transactional
    public AuthResponse loginWithPassword(LoginRequest req) {
        User user = userRepo.findByUsernameIgnoreCase(req.username().trim())
                .filter(u -> u.isActive() && u.getPasswordHash() != null && encoder.matches(req.password(), u.getPasswordHash()))
                .orElseThrow(() -> {
                    audit.logAs(null, req.username(), "LOGIN_FAILED", "User", null, "Mot de passe incorrect");
                    return new BusinessException(HttpStatus.UNAUTHORIZED, "BAD_CREDENTIALS", "Identifiant ou mot de passe incorrect.");
                });
        return issue(user, "PASSWORD");
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
