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

    /** Ingredient nomme : « Thon », abrege « Thon » ; « Mozarilla 3arbi », abrege « Moz3 ». */
    public record ImportIngredient(@NotBlank String name, String shortName) {}

    public record ImportVariantValue(@NotBlank String name, String shortName) {}

    /** Axe de declinaison : « Pate », valeurs Normale / Cereale / Chia. */
    public record ImportVariant(@NotBlank String name, String namePosition, List<ImportVariantValue> values) {}

    /** Prix complet de l'article pour une valeur, jamais un supplement. */
    public record ImportVariantPrice(@NotBlank String value, BigDecimal price) {}

    public record ImportProduct(@NotBlank String code, @NotBlank String name, String shortName, String description,
                                @NotBlank String category, BigDecimal price, BigDecimal taxRate, String color,
                                Integer sortOrder, Boolean favorite, Integer favoriteOrder,
                                List<String> modifierGroups, List<String> printDestinations,
                                List<String> ingredients, String variant, String defaultVariantValue,
                                Boolean askVariant, List<ImportVariantPrice> variantPrices, Boolean priceToCheck,
                                /*
                                    La boutique. Le code-barres identifie l'article au scan ;
                                    le prix d'achat et le suivi de stock voyagent avec lui,
                                    sans quoi une carte importee arriverait muette sur ce qui
                                    fait justement le metier.
                                */
                                String barcode, BigDecimal purchasePrice, Boolean stockManaged, BigDecimal stockMin,
                                /*
                                    PIECE, KG ou LITRE. Une carte de patisserie annonce ses
                                    baklawas au kilo : sans cela, l'import les livrerait
                                    vendables au kilo entier seulement.
                                */
                                String unite) {}

    public record CatalogImport(String label, List<ImportCategory> categories,
                                List<ImportModifierGroup> modifierGroups, List<ImportIngredient> ingredients,
                                List<ImportVariant> variants, List<ImportProduct> products) {}

    public record ImportResult(String label, int categoriesCreated, int categoriesUpdated, int groupsCreated,
                               int groupsUpdated, int productsCreated, int productsUpdated, int productsDeactivated,
                               int categoriesDeactivated, int ingredientsCreated, int variantsCreated,
                               int pricesToCheck, List<String> warnings) {}
}
