package com.poscaisse.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

public final class AdminDtos {
    private AdminDtos() {}

    public record UserDto(Long id, String username, String fullName, Long roleId, String roleCode, String roleName, Long pointOfSaleId,
                          BigDecimal maxDiscountPercent, String color, boolean active, boolean hasPin, boolean hasPassword, OffsetDateTime lastLoginAt) {}
    public record UserRequest(@NotBlank String username, @NotBlank String fullName, @NotNull Long roleId, Long pointOfSaleId,
                              BigDecimal maxDiscountPercent, String color, Boolean active, String password, String pin) {}

    public record RoleDto(Long id, String code, String name, boolean systemRole, List<String> permissions, long userCount) {}
    public record RoleRequest(@NotBlank String code, @NotBlank String name, List<String> permissions) {}

    public record CompanyDto(Long id, String name, String tradeName, String address, String phone, String taxId, String currency,
                             String currencySymbol, int decimals, String timezone, String logoData) {}
    public record CompanyRequest(@NotBlank String name, String tradeName, String address, String phone, String taxId, String currency,
                                 String currencySymbol, Integer decimals, String timezone, String logoData) {}

    public record PointOfSaleDto(Long id, String code, String name, String address, String phone, boolean active, int registerCount) {}
    public record PointOfSaleRequest(@NotBlank String code, @NotBlank String name, String address, String phone, Boolean active) {}

    public record RegisterDto(Long id, String code, String name, Long pointOfSaleId, String pointOfSaleName, boolean active) {}
    public record RegisterRequest(@NotBlank String code, @NotBlank String name, @NotNull Long pointOfSaleId, Boolean active) {}

    public record PrintDestinationDto(Long id, String code, String name, String kind, int copies, boolean showPrices, int sortOrder, boolean active) {}
    public record PrintDestinationRequest(@NotBlank String code, @NotBlank String name, String kind, Integer copies, Boolean showPrices, Integer sortOrder, Boolean active) {}

    public record ReceiptTemplateDto(Long id, String code, String name, int paperWidth, int fontSize, int marginMm, boolean showLogo,
                                     String headerText, String footerText, Map<String, Object> config) {}
    public record ReceiptTemplateRequest(String name, Integer paperWidth, Integer fontSize, Integer marginMm, Boolean showLogo,
                                         String headerText, String footerText, Map<String, Object> config) {}

    public record SettingsDto(Map<String, String> settings) {}

    public record AuditDto(Long id, Long userId, String username, String action, String entityType, String entityId, String details, OffsetDateTime createdAt) {}
    public record CustomerDto(Long id, String name, String phone, String note, OffsetDateTime createdAt) {}
    public record CustomerRequest(@NotBlank String name, String phone, String note) {}

    public record CourierDto(Long id, String name, String phone, String note, boolean active, OffsetDateTime createdAt) {}
    public record CourierRequest(@NotBlank String name, String phone, String note, Boolean active) {}

    public record KitchenNoteDto(Long id, String label, int sortOrder, boolean active) {}
    public record IngredientDto(Long id, String name, int sortOrder, boolean active) {}
    public record IngredientRequest(@NotBlank String name, Integer sortOrder, Boolean active) {}
    public record KitchenNoteRequest(@NotBlank String label, Integer sortOrder, Boolean active) {}
}
