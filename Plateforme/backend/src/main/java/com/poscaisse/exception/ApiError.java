package com.poscaisse.exception;

import java.time.OffsetDateTime;
import java.util.Map;

public record ApiError(int status, String code, String message, Map<String, String> fields, OffsetDateTime timestamp) {
    public static ApiError of(int status, String code, String message) { return new ApiError(status, code, message, null, OffsetDateTime.now()); }
}
