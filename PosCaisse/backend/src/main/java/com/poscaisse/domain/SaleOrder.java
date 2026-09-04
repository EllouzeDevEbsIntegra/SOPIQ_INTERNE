package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "sale_order") @Getter @Setter
public class SaleOrder {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String clientRef;
    private String ticketNumber;
    private String heldRef;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "company_id") private Company company;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "register_id") private Register register;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "session_id") private RegisterSession session;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "cashier_id") private User cashier;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "customer_id") private Customer customer;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "courier_id") private Courier courier;
    private String customerName;
    private String customerPhone;
    private String note;
    @Enumerated(EnumType.STRING) private Enums.ServiceMode serviceMode = Enums.ServiceMode.TAKEAWAY;
    @Enumerated(EnumType.STRING) private Enums.OrderStatus status;
    private BigDecimal subtotal = BigDecimal.ZERO;
    private BigDecimal lineDiscountTotal = BigDecimal.ZERO;
    private BigDecimal discountPercent = BigDecimal.ZERO;
    private BigDecimal discountAmount = BigDecimal.ZERO;
    private BigDecimal taxTotal = BigDecimal.ZERO;
    private BigDecimal total = BigDecimal.ZERO;
    private BigDecimal paidTotal = BigDecimal.ZERO;
    private BigDecimal changeAmount = BigDecimal.ZERO;
    private BigDecimal refundedTotal = BigDecimal.ZERO;
    private String cancelReason;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "cancelled_by") private User cancelledBy;
    private OffsetDateTime cancelledAt;
    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime paidAt;
    private OffsetDateTime updatedAt = OffsetDateTime.now();
    @Version private Long version;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("sortOrder ASC, id ASC")
    private List<OrderLine> lines = new ArrayList<>();

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("id ASC")
    private List<Payment> payments = new ArrayList<>();
}
