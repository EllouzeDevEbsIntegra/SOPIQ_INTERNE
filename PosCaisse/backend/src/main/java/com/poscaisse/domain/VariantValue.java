package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

/** Une valeur d'un axe : « Large », « Chia », « 1/2 ». */
@Entity @Table(name = "variant_value") @Getter @Setter
public class VariantValue {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_id") private Variant variant;
    private String name;

    /**
     * Nom porté par le ticket. Le papier fait 42 colonnes : « L » y coûte cinq caractères
     * de moins que « Large » sur chaque ligne. Vide, c'est le nom complet qui s'imprime.
     */
    private String shortName;

    private int sortOrder;
    private boolean active = true;

    /** Ce qui s'imprime : le nom court s'il existe, le nom complet sinon. */
    @Transient
    public String ticketName() {
        return shortName == null || shortName.isBlank() ? name : shortName;
    }
}
