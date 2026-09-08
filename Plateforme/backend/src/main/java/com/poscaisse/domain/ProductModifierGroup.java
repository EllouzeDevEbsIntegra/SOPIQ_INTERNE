package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.io.Serializable;
import java.util.Objects;

@Entity @Table(name = "product_modifier_group") @Getter @Setter
@IdClass(ProductModifierGroup.Key.class)
public class ProductModifierGroup {
    @Id @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "product_id") private Product product;
    @Id @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "modifier_group_id") private ModifierGroup modifierGroup;
    private int sortOrder;

    @Getter @Setter
    public static class Key implements Serializable {
        private Long product;
        private Long modifierGroup;
        @Override public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key k)) return false;
            return Objects.equals(product, k.product) && Objects.equals(modifierGroup, k.modifierGroup);
        }
        @Override public int hashCode() { return Objects.hash(product, modifierGroup); }
    }
}
