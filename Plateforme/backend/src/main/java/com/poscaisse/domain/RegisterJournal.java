package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity @Table(name = "register_journal") @Getter @Setter
public class RegisterJournal {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "register_id") private Register register;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "session_id") private RegisterSession session;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User user;
    @Enumerated(EnumType.STRING) private Enums.JournalEvent eventType;
    private BigDecimal amount;
    private String reference;
    private String description;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
