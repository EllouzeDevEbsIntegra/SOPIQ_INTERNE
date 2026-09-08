package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity @Table(name = "payment") @Getter @Setter
public class Payment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private SaleOrder order;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "session_id") private RegisterSession session;
    @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "payment_method_id") private PaymentMethod paymentMethod;
    private BigDecimal amount;
    private BigDecimal tendered;
    private BigDecimal changeGiven = BigDecimal.ZERO;
    private String reference;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
