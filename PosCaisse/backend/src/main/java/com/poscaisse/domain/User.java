package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity @Table(name = "app_user") @Getter @Setter
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String username;
    private String fullName;
    private String passwordHash;
    private String pinHash;
    @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "role_id") private Role role;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "point_of_sale_id") private PointOfSale pointOfSale;
    private BigDecimal maxDiscountPercent;
    private String color;
    private boolean active = true;
    private OffsetDateTime lastLoginAt;
    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
