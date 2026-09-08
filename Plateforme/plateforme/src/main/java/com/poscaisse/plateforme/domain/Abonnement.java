package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

/**
 * Ce qui a ete vendu : un metier, un nombre de caisses, une echeance.
 *
 * L'abonnement porte aussi ce que le provisionnement a cree - le nom de la base, l'adresse
 * de la caisse, la version installee. C'est la qu'on regarde quand un client appelle : on
 * sait tout de suite ce qu'il a et sur quoi il tourne.
 */
@Entity @Table(name = "abonnement") @Getter @Setter
public class Abonnement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "client_id") private Client client;

    @Enumerated(EnumType.STRING) private Enums.Module module;
    @Enumerated(EnumType.STRING) private Enums.Formule formule = Enums.Formule.MENSUEL;
    private int nbCaisses = 1;
    private BigDecimal prixMensuel = BigDecimal.ZERO;
    private LocalDate debutLe;
    private LocalDate finLe;
    @Enumerated(EnumType.STRING) private Enums.StatutAbonnement statut = Enums.StatutAbonnement.ACTIF;

    /**
     * Partir de la carte de demonstration du metier, ou d'un catalogue vide.
     *
     * Decide a la vente, garde ici : la commande de lancement se rejoue telle quelle le
     * jour ou le poste est remplace.
     */
    private boolean avecDemonstration = true;

    private String baseNom;
    private String urlClient;
    private String version;
    private OffsetDateTime provisionneLe;

    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
