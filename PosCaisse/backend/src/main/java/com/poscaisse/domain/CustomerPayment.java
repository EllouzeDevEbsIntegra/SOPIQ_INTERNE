package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/** Règlement d'un client sur son compte : il diminue sa dette, sans lien avec un ticket précis. */
@Entity @Table(name = "customer_payment") @Getter @Setter
public class CustomerPayment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String number;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "customer_id") private Customer customer;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "payment_method_id") private PaymentMethod paymentMethod;
    private BigDecimal amount = BigDecimal.ZERO;
    private OffsetDateTime paidAt = OffsetDateTime.now();
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User user;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "session_id") private RegisterSession session;
    private String note;
}
