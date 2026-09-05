package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Axe de déclinaison d'un article : Taille, Pâte, Format.
 *
 * Ce n'est pas une option : le client commande « une pizza thon large », pas « une pizza
 * thon avec du large ». La valeur choisie porte donc un prix complet et entre dans le nom
 * imprimé, au lieu de s'ajouter en ligne de supplément.
 */
@Entity @Table(name = "variant") @Getter @Setter
public class Variant {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;

    /** Où la valeur se place dans le nom : « Pizza Thon Large » ou « 1/2 Sandwich ». */
    @Enumerated(EnumType.STRING) @Column(name = "name_position")
    private Enums.NamePosition namePosition = Enums.NamePosition.SUFFIX;

    private int sortOrder;
    private boolean active = true;
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @OneToMany(mappedBy = "variant", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("sortOrder ASC, id ASC")
    private List<VariantValue> values = new ArrayList<>();
}
