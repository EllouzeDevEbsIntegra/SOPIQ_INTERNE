package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity @Table(name = "daily_closure") @Getter @Setter
public class DailyClosure {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    private LocalDate businessDate;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "closed_by") private User closedBy;
    private OffsetDateTime closedAt = OffsetDateTime.now();
    private BigDecimal revenue = BigDecimal.ZERO;
    private int ticketsCount;
    private BigDecimal averageTicket = BigDecimal.ZERO;
    private BigDecimal cashTotal = BigDecimal.ZERO;
    private BigDecimal cardTotal = BigDecimal.ZERO;
    private BigDecimal otherTotal = BigDecimal.ZERO;
    private BigDecimal discountsTotal = BigDecimal.ZERO;
    private int cancellationsCount;
    private BigDecimal cancellationsTotal = BigDecimal.ZERO;
    private BigDecimal refundsTotal = BigDecimal.ZERO;
    private BigDecimal cashIn = BigDecimal.ZERO;
    private BigDecimal cashOut = BigDecimal.ZERO;
    private BigDecimal cashDifference = BigDecimal.ZERO;
    @Column(columnDefinition = "text") private String detailsJson;
    private String note;
}
