package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Un client : la maison, pas la boutique.
 *
 * Une meme raison sociale peut tenir deux restaurants et un cafe. C'est elle qu'on
 * facture, et c'est a elle que se rattachent les abonnements - un par metier et par
 * etablissement.
 */
@Entity @Table(name = "client") @Getter @Setter
public class Client {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;

    /** CLI-0001 : un code court, qu'on puisse dire au telephone sans l'epeler. */
    private String code;

    private String raisonSociale;
    private String enseigne;
    private String contactNom;
    private String contactTel;
    private String contactEmail;
    private String ville;
    private String adresse;
    private String matriculeFiscal;

    @Enumerated(EnumType.STRING) private Enums.StatutClient statut = Enums.StatutClient.PROSPECT;
    private String notes;
    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @OneToMany(mappedBy = "client", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("id ASC")
    @org.hibernate.annotations.BatchSize(size = 50)
    private List<Abonnement> abonnements = new ArrayList<>();

    @OneToMany(mappedBy = "client", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("emiseLe DESC")
    @org.hibernate.annotations.BatchSize(size = 50)
    private List<Facture> factures = new ArrayList<>();
}
