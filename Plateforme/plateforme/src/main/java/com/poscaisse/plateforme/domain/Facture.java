package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Une periode facturee.
 *
 * Le solde n'est pas une colonne : il se deduit du montant moins les reglements. Un solde
 * stocke finit toujours par ne plus correspondre a son detail, et c'est le detail qu'on
 * montre au client quand il conteste.
 */
@Entity @Table(name = "facture") @Getter @Setter
public class Facture {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "client_id") private Client client;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "abonnement_id") private Abonnement abonnement;

    private String numero;
    private LocalDate periodeDebut;
    private LocalDate periodeFin;
    private BigDecimal montant = BigDecimal.ZERO;
    private LocalDate emiseLe;
    private LocalDate echeanceLe;
    @Enumerated(EnumType.STRING) private Enums.StatutFacture statut = Enums.StatutFacture.EMISE;
    private String libelle;
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @OneToMany(mappedBy = "facture", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("recuLe ASC, id ASC")
    @org.hibernate.annotations.BatchSize(size = 50)
    private List<Reglement> reglements = new ArrayList<>();

    /** Ce qui a ete encaisse sur cette facture. */
    public BigDecimal regle() {
        return reglements.stream().map(Reglement::getMontant).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /** Ce qui reste du. Jamais negatif : un trop-percu se traite a part, pas en silence. */
    public BigDecimal reste() {
        BigDecimal r = montant.subtract(regle());
        return r.signum() < 0 ? BigDecimal.ZERO : r;
    }
}
