package com.poscaisse.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class BusinessException extends RuntimeException {
    private final HttpStatus status;
    private final String code;

    public BusinessException(String message) { this(HttpStatus.BAD_REQUEST, "BUSINESS_RULE", message); }
    public BusinessException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }
    public static BusinessException notFound(String what) { return new BusinessException(HttpStatus.NOT_FOUND, "NOT_FOUND", what + " introuvable."); }
    public static BusinessException conflict(String message) { return new BusinessException(HttpStatus.CONFLICT, "CONFLICT", message); }
    public static BusinessException forbidden(String message) { return new BusinessException(HttpStatus.FORBIDDEN, "FORBIDDEN", message); }
}
