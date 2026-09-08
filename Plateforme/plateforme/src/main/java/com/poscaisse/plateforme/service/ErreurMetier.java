package com.poscaisse.plateforme.service;

import org.springframework.http.HttpStatus;

/** Une erreur qu'on peut montrer telle quelle : elle est ecrite pour etre lue. */
public class ErreurMetier extends RuntimeException {
    private final HttpStatus statut;
    private final String code;

    public ErreurMetier(String message) { this(HttpStatus.BAD_REQUEST, "REGLE_METIER", message); }

    public ErreurMetier(HttpStatus statut, String code, String message) {
        super(message);
        this.statut = statut;
        this.code = code;
    }

    public static ErreurMetier introuvable(String quoi) {
        return new ErreurMetier(HttpStatus.NOT_FOUND, "INTROUVABLE", quoi + " introuvable.");
    }

    public static ErreurMetier interdit(String message) {
        return new ErreurMetier(HttpStatus.FORBIDDEN, "INTERDIT", message);
    }

    public HttpStatus getStatut() { return statut; }
    public String getCode() { return code; }
}
