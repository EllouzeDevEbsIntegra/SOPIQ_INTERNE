package com.poscaisse.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.Set;

public final class AuthDtos {
    private AuthDtos() {}
    public record LoginRequest(@NotBlank String username, @NotBlank String password) {}
    public record PinLoginRequest(Long userId, @NotBlank String pin) {}
    public record UserTile(Long id, String fullName, String username, String color, String roleCode, String roleName) {}
    public record CurrentUserDto(Long id, String username, String fullName, String roleCode, String roleName,
                                 Set<String> permissions, Long pointOfSaleId, java.math.BigDecimal maxDiscountPercent) {}
    public record AuthResponse(String token, CurrentUserDto user, SessionInfo openSession) {}
    public record SessionInfo(Long id, Long registerId, String registerCode, String registerName, Long pointOfSaleId,
                              String pointOfSaleName, java.time.OffsetDateTime openedAt, java.math.BigDecimal openingFloat,
                              Long openedById, String openedByName) {}
    public record ChangePinRequest(@NotBlank String currentPin, @NotBlank String newPin) {}
    public record PermissionList(List<String> permissions) {}
}
