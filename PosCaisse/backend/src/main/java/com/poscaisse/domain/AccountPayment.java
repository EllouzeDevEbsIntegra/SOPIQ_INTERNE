package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Règlement porté sur un compte — celui d'un client ou celui d'un livreur. Il diminue la
 * dette du titulaire sans se rattacher à un ticket précis.
 *
 * Exactement l'une des deux références est renseignée ; la contrainte est aussi en base,
 * pour qu'un règlement ne puisse jamais se retrouver sans titulaire ni avec deux.
 */
@Entity @Table(name = "account_payment") @Getter @Setter
public class AccountPayment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String number;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "customer_id") private Customer customer;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "courier_id") private Courier courier;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "payment_method_id") private PaymentMethod paymentMethod;
    private BigDecimal amount = BigDecimal.ZERO;
    private OffsetDateTime paidAt = OffsetDateTime.now();
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User user;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "session_id") private RegisterSession session;
    private String note;
}
