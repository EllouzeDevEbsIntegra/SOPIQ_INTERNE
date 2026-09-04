package com.poscaisse.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public final class CatalogDtos {
    private CatalogDtos() {}

    public record CategoryDto(Long id, String name, String color, String icon, int sortOrder, boolean active, Long printDestinationId, long productCount) {}
    public record CategoryRequest(@NotBlank String name, String color, String icon, Integer sortOrder, Boolean active, Long printDestinationId) {}

    public record ModifierDto(Long id, String name, BigDecimal priceDelta, int sortOrder, boolean active) {}
    public record ModifierGroupDto(Long id, String name, boolean required, boolean multiple, int minSelect, int maxSelect, int sortOrder, boolean active, List<ModifierDto> modifiers) {}
    public record ModifierRequest(Long id, @NotBlank String name, BigDecimal priceDelta, Integer sortOrder, Boolean active) {}
    public record ModifierGroupRequest(@NotBlank String name, Boolean required, Boolean multiple, Integer minSelect, Integer maxSelect, Integer sortOrder, Boolean active, List<ModifierRequest> modifiers) {}

    public record MenuOptionDto(Long productId, String productName, BigDecimal priceDelta, boolean available) {}
    public record MenuComponentDto(Long id, String name, int quantity, int sortOrder, List<MenuOptionDto> options) {}
    public record MenuOptionRequest(@NotNull Long productId, BigDecimal priceDelta) {}
    public record MenuComponentRequest(@NotBlank String name, Integer quantity, Integer sortOrder, List<MenuOptionRequest> options) {}

    public record ProductDto(Long id, String code, String reference, String name, String shortName, String description,
                             Long categoryId, String categoryName, String productType, BigDecimal price, BigDecimal taxRate,
                             String imageUrl, String color, int sortOrder, boolean active, boolean available, boolean favorite,
                             int favoriteOrder, List<Long> printDestinationIds, List<ModifierGroupDto> modifierGroups,
                             List<MenuComponentDto> menuComponents) {}

    public record ProductRequest(@NotBlank String code, String reference, @NotBlank String name, String shortName, String description,
                                 @NotNull Long categoryId, String productType, @NotNull BigDecimal price, BigDecimal taxRate,
                                 String imageUrl, String color, Integer sortOrder, Boolean active, Boolean available, Boolean favorite,
                                 Integer favoriteOrder, List<Long> printDestinationIds, List<Long> modifierGroupIds,
                                 List<MenuComponentRequest> menuComponents) {}

    public record PaymentMethodDto(Long id, String code, String name, String kind, boolean opensDrawer, int sortOrder, boolean active) {}
    public record PaymentMethodRequest(@NotBlank String code, @NotBlank String name, @NotBlank String kind, Boolean opensDrawer, Integer sortOrder, Boolean active) {}

    public record ReorderRequest(List<Long> ids) {}
    public record FavoritesRequest(List<Long> productIds) {}
    public record AvailabilityRequest(@NotNull Boolean available) {}

    public record CatalogResponse(List<CategoryDto> categories, List<ProductDto> products, List<PaymentMethodDto> paymentMethods,
                                  Map<String, String> settings, CompanyInfo company) {}
    public record CompanyInfo(String name, String tradeName, String currency, String currencySymbol, int decimals, String logoData) {}
}
