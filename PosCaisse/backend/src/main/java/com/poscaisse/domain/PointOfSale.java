package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

@Entity @Table(name = "point_of_sale") @Getter @Setter
public class PointOfSale {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "company_id") private Company company;
    private String code;
    private String name;
    private String address;
    private String phone;
    private boolean active = true;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
