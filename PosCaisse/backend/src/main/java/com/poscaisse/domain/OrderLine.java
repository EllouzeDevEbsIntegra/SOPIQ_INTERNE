package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "order_line") @Getter @Setter
public class OrderLine {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private SaleOrder order;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "parent_line_id") private OrderLine parentLine;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "product_id") private Product product;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "category_id") private Category category;
    private String productCode;
    private String productName;
    private BigDecimal quantity = BigDecimal.ONE;
    private BigDecimal originalUnitPrice = BigDecimal.ZERO;
    private BigDecimal unitPrice = BigDecimal.ZERO;
    private BigDecimal modifiersTotal = BigDecimal.ZERO;
    private BigDecimal discountPercent = BigDecimal.ZERO;
    private BigDecimal discountAmount = BigDecimal.ZERO;
    private BigDecimal taxRate = BigDecimal.ZERO;
    private BigDecimal lineTotal = BigDecimal.ZERO;
    private String note;
    private int sortOrder;
    @OneToMany(mappedBy = "orderLine", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("id ASC")
    private List<OrderLineModifier> modifiers = new ArrayList<>();
    @OneToMany(mappedBy = "parentLine", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("sortOrder ASC, id ASC")
    private List<OrderLine> components = new ArrayList<>();
}
