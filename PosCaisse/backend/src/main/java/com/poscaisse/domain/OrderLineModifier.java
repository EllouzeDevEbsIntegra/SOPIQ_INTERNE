package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Entity @Table(name = "order_line_modifier") @Getter @Setter
public class OrderLineModifier {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_line_id") private OrderLine orderLine;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "modifier_id") private Modifier modifier;
    private String modifierName;
    private BigDecimal priceDelta = BigDecimal.ZERO;
    /** Nombre de fois que l'option est ajoutee a la ligne (groupes sans maximum). */
    private int quantity = 1;
}
