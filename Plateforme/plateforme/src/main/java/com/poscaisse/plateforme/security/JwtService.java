package com.poscaisse.plateforme.security;

import com.poscaisse.plateforme.domain.AppSecret;
import com.poscaisse.plateforme.domain.EditeurUser;
import com.poscaisse.plateforme.repository.SecretRepo;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

/**
 * Les jetons du back-office.
 *
 * Meme principe que dans la caisse, et pour la meme raison : aucune cle livree avec le
 * logiciel. Celle-ci est tiree au sort a la premiere connexion et gardee dans une table
 * que rien n'expose. Une cle posee par l'exploitant l'emporte - c'est ce qu'on fera sur le
 * serveur, ou plusieurs instances doivent signer pareil.
 *
 * La session dure DEUX HEURES, contre douze pour une caisse : ce compte-ci voit tous les
 * clients, et un poste laisse ouvert dans un bureau est un risque different d'une caisse
 * sous les yeux du patron.
 */
@Service @RequiredArgsConstructor
public class JwtService {
    private static final String CLE = "jwt.secret";
    private final SecretRepo secrets;

    @Value("${plateforme.jwt.secret:}") private String secretConfigure;
    @Value("${plateforme.jwt.expiration-minutes:120}") private long expirationMinutes;

    private volatile SecretKey key;

    public long dureeMinutes() { return expirationMinutes; }

    public String pour(EditeurUser u) {
        Date maintenant = new Date();
        return Jwts.builder()
                .subject(String.valueOf(u.getId()))
                .claims(Map.of("username", u.getUsername(), "role", u.getRole().name()))
                .issuedAt(maintenant)
                .expiration(new Date(maintenant.getTime() + expirationMinutes * 60_000))
                .signWith(cle())
                .compact();
    }

    public Claims lire(String token) {
        return Jwts.parser().verifyWith(cle()).build().parseSignedClaims(token).getPayload();
    }

    private SecretKey cle() {
        SecretKey k = key;
        if (k != null) return k;
        synchronized (this) {
            if (key == null) key = Keys.hmacShaKeyFor(resoudre().getBytes(StandardCharsets.UTF_8));
            return key;
        }
    }

    private String resoudre() {
        if (secretConfigure != null && !secretConfigure.isBlank()) return secretConfigure;
        String existant = secrets.findById(CLE).map(AppSecret::getValue).orElse(null);
        if (existant != null) return existant;
        byte[] alea = new byte[48];
        new SecureRandom().nextBytes(alea);
        secrets.poserSiAbsent(CLE, Base64.getEncoder().encodeToString(alea));
        return secrets.findById(CLE).map(AppSecret::getValue)
                .orElseThrow(() -> new IllegalStateException("Impossible d'établir la clé de signature."));
    }
}
