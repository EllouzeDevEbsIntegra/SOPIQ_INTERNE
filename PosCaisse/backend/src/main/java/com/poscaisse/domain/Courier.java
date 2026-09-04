package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

/** Livreur : sélectionné sur un ticket en livraison, et titulaire d'un compte comme un client. */
@Entity @Table(name = "courier") @Getter @Setter
public class Courier {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;
    private String phone;
    private String note;
    private boolean active = true;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
