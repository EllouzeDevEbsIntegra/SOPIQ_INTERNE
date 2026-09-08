package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/** Un compte de chez nous : admin, commercial ou support. */
@Entity @Table(name = "editeur_user") @Getter @Setter
public class EditeurUser {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String username;
    private String fullName;
    private String email;
    private String passwordHash;
    @Enumerated(EnumType.STRING) private Enums.Role role = Enums.Role.SUPPORT;
    private boolean active = true;
    private OffsetDateTime lastLoginAt;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
