package com.poscaisse.dto;

import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

/** Le stock des pates, tel que l'ecran de vente le montre et le fait bouger. */
public class StockDtos {
    /**
     * Une pate suivie : ce qu'il en reste, et ce qui tire dessus.
     *
     * << emprunteurs >> porte les valeurs sans compteur propre, dites telles quelles -
     * << Double Normale x2 >>. Sans elles, le caissier ne comprend pas pourquoi son
     * compteur descend de deux d'un coup.
     */
    public record StockLineDto(Long variantValueId, String variantName, String valueName,
                               BigDecimal quantity, List<String> borrowers) {}

    public record StockMovementDto(Long id, Long variantValueId, String valueName, String type,
                                   BigDecimal quantity, BigDecimal resulting, String userName,
                                   String comment, OffsetDateTime createdAt) {}

    public record StockStateDto(Long pointOfSaleId, String pointOfSaleName,
                                List<StockLineDto> lines, List<StockMovementDto> movements) {}

    /**
     * Un compteur tel que le back-office le montre : la quantite du jour, et ou elle est.
     *
     * Le point de vente est nomme parce qu'il y en aura deux : le meme reglage de
     * variante sert les deux restaurants, mais la pate, elle, est dans un seul frigo.
     */
    public record StockCounterDto(Long variantValueId, Long pointOfSaleId, String pointOfSaleName,
                                  BigDecimal quantity, OffsetDateTime updatedAt) {}

    public record StockMoveRequest(@NotNull Long variantValueId, @NotNull BigDecimal quantity, String comment) {}

    // ------------------------------------------------------------------ le stock des ARTICLES
    /*
        La boutique compte ce qu'elle achete. Une ligne porte donc ce qu'un rayon demande
        pour etre tenu : ce qu'il en reste, le seuil sous lequel il faut recommander, le
        code-barres qui l'identifie au scan, et le dernier prix d'achat connu - celui qui
        pre-remplit la prochaine entree.
    */
    public record ProductStockLineDto(Long productId, String code, String barcode, String name,
                                      String categoryName, BigDecimal quantity, BigDecimal stockMin,
                                      BigDecimal purchasePrice, BigDecimal price, boolean sousLeSeuil) {}

    public record ProductStockMovementDto(Long id, Long productId, String productName, String type,
                                          BigDecimal quantity, BigDecimal resulting, BigDecimal unitCost,
                                          String supplier, String userName, String comment,
                                          OffsetDateTime createdAt) {}

    public record ProductStockStateDto(Long pointOfSaleId, String pointOfSaleName, String mode, String rupture,
                                       List<ProductStockLineDto> lines, List<ProductStockMovementDto> movements) {}

    /**
     * Une entree, une casse ou un inventaire.
     *
     * << quantity >> est ce qu'on ajoute ou ce qu'on retire, sauf pour l'inventaire ou
     * c'est le chiffre COMPTE : l'ecart se deduit, il ne se saisit pas.
     */
    public record ProductStockMoveRequest(@NotNull Long productId, @NotNull BigDecimal quantity,
                                          BigDecimal unitCost, String supplier, String comment) {}
}
