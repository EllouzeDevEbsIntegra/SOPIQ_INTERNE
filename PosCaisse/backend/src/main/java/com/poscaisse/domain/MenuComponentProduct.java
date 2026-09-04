package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

@Entity @Table(name = "menu_component_product") @Getter @Setter
@IdClass(MenuComponentProduct.Key.class)
public class MenuComponentProduct {
    @Id @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "menu_component_id") private MenuComponent component;
    @Id @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "product_id") private Product product;
    private BigDecimal priceDelta = BigDecimal.ZERO;

    @Getter @Setter
    public static class Key implements Serializable {
        private Long component;
        private Long product;
        @Override public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key k)) return false;
            return Objects.equals(component, k.component) && Objects.equals(product, k.product);
        }
        @Override public int hashCode() { return Objects.hash(component, product); }
    }
}
