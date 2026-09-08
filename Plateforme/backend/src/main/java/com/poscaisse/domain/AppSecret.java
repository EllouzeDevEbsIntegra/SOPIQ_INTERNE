package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/**
 * Un secret propre a cette installation - la cle de signature des jetons, aujourd'hui.
 *
 * Il vit dans sa propre table, a l'ecart des reglages : rien ne le sert, rien ne
 * l'affiche, et aucun ecran ne risque de le montrer par distraction.
 */
@Entity @Table(name = "app_secret") @Getter @Setter
public class AppSecret {
    @Id private String key;
    @Column(columnDefinition = "text") private String value;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
