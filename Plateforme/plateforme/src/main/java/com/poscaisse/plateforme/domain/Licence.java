package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Le droit d'ouvrir une caisse.
 *
 * Verifiee au serveur a chaque ouverture, et non posee sur le poste : une cle dans un
 * fichier se copie d'une machine a l'autre, et on ne le sait jamais. Le nombre de postes
 * est celui qui a ete vendu ; la caisse suivante est refusee, avec la phrase qui dit
 * pourquoi et qui appeler.
 */
@Entity @Table(name = "licence") @Getter @Setter
public class Licence {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "abonnement_id") private Abonnement abonnement;

    private String cle;
    private int postesMax = 1;
    private LocalDate expireLe;
    private boolean revoquee = false;
    private OffsetDateTime derniereVerif;
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @OneToMany(mappedBy = "licence", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<LicenceActivation> activations = new ArrayList<>();
}
