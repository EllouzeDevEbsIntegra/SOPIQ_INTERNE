package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

/**
 * Ce que vaut, et à quoi ressemble, un article dans une de ses versions.
 *
 * Le prix est complet, pas un supplément : « Pizza Thon Large = 18 DT ». Une valeur sans
 * ligne ici, ou à prix nul, n'est pas vendable — c'est le cas d'une valeur ajoutée à
 * l'axe après le paramétrage de l'article.
 *
 * La photo, elle, est facultative de bout en bout : la caisse montre celle de la version
 * si elle existe, sinon celle de l'article, sinon rien.
 */
@Entity @Table(name = "product_variant_price") @IdClass(ProductVariantPrice.Cle.class) @Getter @Setter
public class ProductVariantPrice {
    @Id @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "product_id") private Product product;
    @Id @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_value_id") private VariantValue value;
    private BigDecimal price = BigDecimal.ZERO;
    /** Photo propre a cette version. Nulle : celle de l'article prend le relais. */
    @Column(columnDefinition = "text") private String imageUrl;

    @Getter @Setter
    public static class Cle implements Serializable {
        private Long product;
        private Long value;
        @Override public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Cle c)) return false;
            return Objects.equals(product, c.product) && Objects.equals(value, c.value);
        }
        @Override public int hashCode() { return Objects.hash(product, value); }
    }
}
