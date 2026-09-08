package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Ce qui a fait bouger le compteur d'un article.
 *
 * Le soir, il manque trois bouteilles : vendues, cassees, ou jamais entrees ? Sans cette
 * trace, la question n'a pas de reponse. La quantite est SIGNEE et le compteur d'apres
 * est fige, pour ne pas avoir a rejouer la journee.
 *
 * Le PRIX D'ACHAT est garde sur l'entree, et sur elle seule : il change d'un
 * approvisionnement a l'autre, et c'est lui qui donne la marge reelle - pas celui de la
 * fiche article, qui n'est qu'un dernier prix connu.
 */
@Entity @Table(name = "product_stock_movement") @Getter @Setter
public class ProductStockMovement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "product_id") private Product product;
    @Enumerated(EnumType.STRING) @Column(name = "movement_type") private Enums.StockMovement movementType;
    private BigDecimal quantity;
    private BigDecimal resulting;
    private BigDecimal unitCost;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private SaleOrder order;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User user;
    private String supplier;
    private String comment;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
