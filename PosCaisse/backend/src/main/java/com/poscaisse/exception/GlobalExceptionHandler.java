package com.poscaisse.exception;

import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice @Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiError> business(BusinessException e) {
        return ResponseEntity.status(e.getStatus()).body(ApiError.of(e.getStatus().value(), e.getCode(), e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> validation(MethodArgumentNotValidException e) {
        Map<String, String> fields = new LinkedHashMap<>();
        e.getBindingResult().getFieldErrors().forEach(f -> fields.put(f.getField(), f.getDefaultMessage()));
        String msg = fields.isEmpty() ? "Données invalides." : "Données invalides : " + String.join(", ", fields.values());
        return ResponseEntity.badRequest().body(new ApiError(400, "VALIDATION", msg, fields, OffsetDateTime.now()));
    }

    @ExceptionHandler({ConstraintViolationException.class, HttpMessageNotReadableException.class, IllegalArgumentException.class, org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class, org.springframework.web.bind.MissingServletRequestParameterException.class})
    public ResponseEntity<ApiError> badRequest(Exception e) {
        return ResponseEntity.badRequest().body(ApiError.of(400, "BAD_REQUEST", "Requête invalide : " + rootMessage(e)));
    }

    @ExceptionHandler({AccessDeniedException.class})
    public ResponseEntity<ApiError> denied(Exception e) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiError.of(403, "FORBIDDEN", "Vous n'avez pas la permission d'effectuer cette action."));
    }

    @ExceptionHandler({BadCredentialsException.class, AuthenticationException.class})
    public ResponseEntity<ApiError> auth(Exception e) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiError.of(401, "UNAUTHORIZED", "Identifiants incorrects."));
    }

    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ResponseEntity<ApiError> optimistic(Exception e) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(ApiError.of(409, "CONCURRENT_UPDATE", "Cet élément a été modifié par une autre caisse. Veuillez réessayer."));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> integrity(DataIntegrityViolationException e) {
        String root = rootMessage(e);
        String msg = "Opération impossible : cette donnée est utilisée ailleurs ou existe déjà.";
        if (root.contains("ux_register_session_open")) msg = "Cette caisse possède déjà une session ouverte.";
        else if (root.contains("product_code") || root.contains("code_key")) msg = "Ce code existe déjà.";
        else if (root.contains("username")) msg = "Ce nom d'utilisateur existe déjà.";
        else if (root.contains("client_ref")) msg = "Cette vente a déjà été validée.";
        log.warn("Data integrity: {}", root);
        return ResponseEntity.status(HttpStatus.CONFLICT).body(ApiError.of(409, "DATA_INTEGRITY", msg));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiError> noResource(NoResourceFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiError.of(404, "NOT_FOUND", "Ressource introuvable."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> generic(Exception e) {
        log.error("Unhandled error", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiError.of(500, "INTERNAL", "Une erreur inattendue est survenue. Veuillez réessayer."));
    }

    private static String rootMessage(Throwable t) {
        Throwable r = t;
        while (r.getCause() != null && r.getCause() != r) r = r.getCause();
        return r.getMessage() == null ? "" : r.getMessage();
    }
}
