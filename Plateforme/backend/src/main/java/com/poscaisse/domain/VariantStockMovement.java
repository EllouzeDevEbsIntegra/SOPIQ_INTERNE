package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Ce qui a fait bouger un compteur de pate.
 *
 * Sans cette trace, un stock qui ne tombe pas juste le soir ne s'explique pas : on voit
 * un chiffre, jamais ce qui l'a produit. La quantite est SIGNEE, et le compteur d'apres
 * est fige - repondre a << il restait combien a 19 h ? >> ne doit pas obliger a rejouer
 * toute la journee.
 */
@Entity @Table(name = "variant_stock_movement") @Getter @Setter
public class VariantStockMovement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_value_id") private VariantValue variantValue;
    @Enumerated(EnumType.STRING) @Column(name = "movement_type") private Enums.StockMovement movementType;
    private BigDecimal quantity;
    private BigDecimal resulting;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private SaleOrder order;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User user;
    private String comment;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
