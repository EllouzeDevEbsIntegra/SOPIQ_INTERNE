package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Entity @Table(name = "modifier") @Getter @Setter
public class Modifier {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "group_id") private ModifierGroup group;
    private String name;
    private BigDecimal priceDelta = BigDecimal.ZERO;
    private int sortOrder;
    private boolean active = true;
}
