package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Le compteur d'un article, pour un point de vente.
 *
 * La boutique compte ce qu'elle achete : une bouteille, un paquet de biscuits, une
 * recharge. Le compteur appartient donc au POINT DE VENTE - deux caisses face au meme
 * rayon doivent voir le meme chiffre, sinon la derniere bouteille se vend deux fois.
 *
 * A ne pas confondre avec {@link VariantStock}, qui compte la PATE du restaurant : la
 * meme pate sert quarante sandwichs, elle ne se scanne pas et ne s'achete pas a l'unite.
 * Les deux comptages coexistent sans se rencontrer.
 */
@Entity @Table(name = "product_stock") @Getter @Setter
public class ProductStock {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "product_id") private Product product;
    private BigDecimal quantity = BigDecimal.ZERO;
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
