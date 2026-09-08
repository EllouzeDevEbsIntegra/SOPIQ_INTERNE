package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/** Une caisse qui s'est presentee avec la licence : une empreinte, deux dates. */
@Entity @Table(name = "licence_activation") @Getter @Setter
public class LicenceActivation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "licence_id") private Licence licence;
    private String empreinte;
    private String libelle;
    private OffsetDateTime premiereLe = OffsetDateTime.now();
    private OffsetDateTime derniereLe = OffsetDateTime.now();
}
