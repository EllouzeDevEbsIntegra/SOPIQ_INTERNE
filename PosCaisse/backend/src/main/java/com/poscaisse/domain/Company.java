package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

@Entity @Table(name = "company") @Getter @Setter
public class Company {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;
    private String tradeName;
    private String address;
    private String phone;
    private String taxId;
    private String currency = "TND";
    private String currencySymbol = "DT";
    private Integer decimals = 3;
    private String timezone = "Africa/Tunis";
    @Column(columnDefinition = "text") private String logoData;
    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
