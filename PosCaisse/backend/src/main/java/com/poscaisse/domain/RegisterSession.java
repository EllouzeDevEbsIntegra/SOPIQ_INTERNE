package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity @Table(name = "register_session") @Getter @Setter
public class RegisterSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "register_id") private Register register;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "opened_by") private User openedBy;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "closed_by") private User closedBy;
    @Enumerated(EnumType.STRING) private Enums.SessionStatus status = Enums.SessionStatus.OPEN;
    private OffsetDateTime openedAt = OffsetDateTime.now();
    private OffsetDateTime closedAt;
    private BigDecimal openingFloat = BigDecimal.ZERO;
    private BigDecimal cashSales;
    private BigDecimal cardSales;
    private BigDecimal otherSales;
    private BigDecimal cashRefunds;
    private BigDecimal cashIn;
    private BigDecimal cashOut;
    private BigDecimal expectedCash;
    private BigDecimal countedCash;
    private BigDecimal cashDifference;
    private Integer ticketsCount;
    private BigDecimal revenue;
    private String closingNote;
    @Version private Long version;
}
