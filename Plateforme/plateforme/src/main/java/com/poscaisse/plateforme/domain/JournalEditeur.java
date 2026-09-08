package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/** Qui a fait quoi, et quand. Sur les contrats de trois cents commercants, ce n'est pas un luxe. */
@Entity @Table(name = "journal_editeur") @Getter @Setter
public class JournalEditeur {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private Long userId;
    private String username;
    private String action;
    private String cibleType;
    private Long cibleId;
    private String details;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
