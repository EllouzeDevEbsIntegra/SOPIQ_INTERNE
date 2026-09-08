package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "payment_method") @Getter @Setter
public class PaymentMethod {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String code;
    private String name;
    @Enumerated(EnumType.STRING) private Enums.PaymentKind kind = Enums.PaymentKind.OTHER;
    private boolean opensDrawer;
    private int sortOrder;
    private boolean active = true;
}
