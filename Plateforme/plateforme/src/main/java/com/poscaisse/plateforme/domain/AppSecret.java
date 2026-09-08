package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/** Le secret de signature, propre a cette installation. Aucun endpoint ne le lit. */
@Entity @Table(name = "app_secret") @Getter @Setter
public class AppSecret {
    @Id private String key;
    @Column(columnDefinition = "text") private String value;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
