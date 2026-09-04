package com.poscaisse.dto;

import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;
import java.util.List;

/** Format d'échange pour l'import d'une carte complète (catégories, options, produits). */
public final class CatalogImportDtos {
    private CatalogImportDtos() {}

    public record ImportModifier(@NotBlank String name, BigDecimal priceDelta) {}

    public record ImportModifierGroup(@NotBlank String name, Boolean required, Boolean multiple,
                                      Integer minSelect, Integer maxSelect, List<ImportModifier> modifiers) {}

    public record ImportCategory(@NotBlank String name, String color, String icon, Integer sortOrder,
                                 String printDestination) {}

    public record ImportProduct(@NotBlank String code, @NotBlank String name, String shortName, String description,
                                @NotBlank String category, BigDecimal price, BigDecimal taxRate, String color,
                                Integer sortOrder, Boolean favorite, Integer favoriteOrder,
                                List<String> modifierGroups, List<String> printDestinations) {}

    public record CatalogImport(String label, List<ImportCategory> categories,
                                List<ImportModifierGroup> modifierGroups, List<ImportProduct> products) {}

    public record ImportResult(String label, int categoriesCreated, int categoriesUpdated, int groupsCreated,
                               int groupsUpdated, int productsCreated, int productsUpdated, int productsDeactivated,
                               int categoriesDeactivated, List<String> warnings) {}
}
