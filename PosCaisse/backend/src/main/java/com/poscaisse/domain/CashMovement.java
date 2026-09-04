package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity @Table(name = "cash_movement") @Getter @Setter
public class CashMovement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "session_id") private RegisterSession session;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User user;
    @Enumerated(EnumType.STRING) private Enums.MovementType movementType;
    private String reason;
    private BigDecimal amount;
    private String comment;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
