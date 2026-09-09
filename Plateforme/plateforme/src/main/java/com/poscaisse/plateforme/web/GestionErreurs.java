package com.poscaisse.plateforme.web;

import com.poscaisse.plateforme.service.ErreurMetier;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Une erreur qui se lit.
 *
 * Jamais de trace d'exception dans une reponse : elle renseigne celui qui cherche une
 * faille et n'apprend rien a celui qui travaille. Le message, lui, est ecrit en francais
 * et dit quoi faire.
 */
@RestControllerAdvice
public class GestionErreurs {

    @ExceptionHandler(ErreurMetier.class)
    public ResponseEntity<Map<String, Object>> metier(ErreurMetier e) {
        return ResponseEntity.status(e.getStatut()).body(corps(e.getStatut().value(), e.getCode(), e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> validation(MethodArgumentNotValidException e) {
        String champs = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getField() + " : " + f.getDefaultMessage())
                .reduce((a, b) -> a + " ; " + b).orElse("Requête invalide.");
        return ResponseEntity.badRequest().body(corps(400, "VALIDATION", champs));
    }

    /**
     * Une adresse qui n'existe pas n'est pas une panne.
     *
     * Chaque navigateur demande /favicon.ico sans qu'on le lui dise, et chaque demande
     * ecrivait << Erreur non prevue >> suivi d'une pile de quarante lignes. Un journal qui
     * crie au loup a chaque chargement de page est un journal que personne ne lit - et
     * c'est la que les vraies erreurs se perdent. On rend 404, sans bruit.
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Map<String, Object>> introuvable(NoResourceFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(corps(404, "INTROUVABLE", "Cette adresse n'existe pas."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> reste(Exception e) {
        // Le detail part dans les journaux du serveur, pas dans la reponse.
        org.slf4j.LoggerFactory.getLogger(GestionErreurs.class).error("Erreur non prévue", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(corps(500, "ERREUR", "Une erreur est survenue. Réessayez, et prévenez-nous si elle persiste."));
    }

    private Map<String, Object> corps(int statut, String code, String message) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("status", statut);
        m.put("code", code);
        m.put("message", message);
        m.put("timestamp", OffsetDateTime.now());
        return m;
    }
}
