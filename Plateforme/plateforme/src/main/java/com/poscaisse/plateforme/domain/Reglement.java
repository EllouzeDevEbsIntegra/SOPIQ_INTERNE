package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

/** Un versement recu : virement, cheque, especes. Saisi a la main, faute de paiement en ligne. */
@Entity @Table(name = "reglement") @Getter @Setter
public class Reglement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "facture_id") private Facture facture;
    private BigDecimal montant;
    private LocalDate recuLe;
    @Enumerated(EnumType.STRING) private Enums.MoyenReglement moyen = Enums.MoyenReglement.VIREMENT;
    private String reference;
    private String note;
    @Column(name = "saisi_par") private Long saisiPar;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
