package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Le compteur d'une pate, pour un point de vente.
 *
 * Il appartient au POINT DE VENTE et non a la caisse : la pate est dans le frigo du
 * restaurant. Deux caisses qui vendent le meme stock physique doivent voir le meme
 * compteur, sinon chacune se croit seule et la derniere pate se vend deux fois.
 */
@Entity @Table(name = "variant_stock") @Getter @Setter
public class VariantStock {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_value_id") private VariantValue variantValue;
    private BigDecimal quantity = BigDecimal.ZERO;
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
