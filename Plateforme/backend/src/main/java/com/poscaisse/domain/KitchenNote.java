package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

/** Remarque de cuisine proposée au caissier sur une ligne de commande. */
@Entity @Table(name = "kitchen_note") @Getter @Setter
public class KitchenNote {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String label;
    private int sortOrder;
    private boolean active = true;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
