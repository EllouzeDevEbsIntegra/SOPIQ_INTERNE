package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

@Entity @Table(name = "customer") @Getter @Setter
public class Customer {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;
    private String phone;
    private String note;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
