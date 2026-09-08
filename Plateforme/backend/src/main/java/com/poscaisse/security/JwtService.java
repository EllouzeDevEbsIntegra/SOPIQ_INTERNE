package com.poscaisse.security;

import com.poscaisse.domain.AppSecret;
import com.poscaisse.repository.AppSecretRepo;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

/**
 * Les jetons de session, et la cle qui les signe.
 *
 * D'OU VIENT LA CLE. De la configuration quand l'exploitant en a pose une - c'est le cas
 * d'un serveur, ou elle est fournie par l'environnement. Sinon, d'un secret tire au sort a
 * la premiere utilisation et garde en base.
 *
 * POURQUOI CE N'EST PAS UN DETAIL. Le logiciel etait livre avec une cle de developpement
 * ecrite dans le fichier de configuration. Qui l'a lue peut fabriquer un jeton valide -
 * pour n'importe quelle installation, avec n'importe quels droits, sans jamais connaitre
 * un seul mot de passe. Un secret tire au sort par installation ferme cette porte, et sans
 * rien demander a celui qui installe : c'est important, parce qu'un reglage de securite
 * qu'il faut penser a poser n'est pas pose.
 *
 * La cle est resolue A LA PREMIERE DEMANDE, pas au demarrage : la base doit d'abord avoir
 * ete migree, et personne ne se connecte avant que l'application ne reponde.
 */
@Service @RequiredArgsConstructor
public class JwtService {
    private static final Logger log = LoggerFactory.getLogger(JwtService.class);
    /** La valeur livree dans application.yml : sa presence signifie << rien n'a ete pose >>. */
    private static final String DEFAUT_LIVRE = "change-me-please-this-is-a-development-secret-key-with-64-bytes-min-length-0123456789";
    private static final String CLE = "jwt.secret";

    private final AppSecretRepo secrets;
    @Value("${poscaisse.jwt.secret}") private String secretConfigure;
    @Value("${poscaisse.jwt.expiration-minutes}") private long expirationMinutes;

    private volatile SecretKey key;

    public String generate(Long userId, String username, Map<String, Object> claims) {
        Date now = new Date();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("username", username)
                .claims(claims)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMinutes * 60_000))
                .signWith(key())
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload();
    }

    private SecretKey key() {
        SecretKey k = key;
        if (k != null) return k;
        synchronized (this) {
            if (key == null) key = Keys.hmacShaKeyFor(resoudre().getBytes(StandardCharsets.UTF_8));
            return key;
        }
    }

    /**
     * Une cle posee par l'exploitant l'emporte ; sinon celle de cette installation, tiree
     * au sort la premiere fois et gardee ensuite - sans quoi tous les caissiers seraient
     * deconnectes a chaque redemarrage.
     */
    private String resoudre() {
        if (secretConfigure != null && !secretConfigure.isBlank() && !DEFAUT_LIVRE.equals(secretConfigure))
            return secretConfigure;
        String existant = secrets.findById(CLE).map(AppSecret::getValue).orElse(null);
        if (existant != null) return existant;

        byte[] alea = new byte[48];
        new SecureRandom().nextBytes(alea);
        // C'est la base qui tranche entre deux instances qui demarrent ensemble : celle
        // qui arrive seconde ne remplace rien, et relit ce qui a ete pose.
        secrets.poserSiAbsent(CLE, Base64.getEncoder().encodeToString(alea));
        String pose = secrets.findById(CLE).map(AppSecret::getValue)
                .orElseThrow(() -> new IllegalStateException("Impossible d'établir la clé de signature."));
        log.info("Clé de signature propre à cette installation : un jeton d'un poste ne vaut que pour lui.");
        return pose;
    }
}
