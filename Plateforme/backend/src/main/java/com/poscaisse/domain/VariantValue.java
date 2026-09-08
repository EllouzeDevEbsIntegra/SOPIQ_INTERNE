package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

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

    /*
        Le stock du jour, pose sur la valeur et non sur l'article : ce qui s'epuise chez
        un fast-food a mlewi, ce n'est pas << Omlette Thon >>, c'est la PATE. La meme pate
        normale sert quarante sandwichs, et c'est elle qui manque a 21 h.
    */

    /** Suivie ou non. Faux tant que le gerant n'a pas dit lui-meme ce qui se compte. */
    @Column(name = "stock_managed") private boolean stockManaged;

    /** Ce qu'une vente retire du compteur : 1 pate normale, 2 pour une double. */
    @Column(name = "stock_step") private BigDecimal stockStep = BigDecimal.ONE;

    /**
     * La valeur sur laquelle celle-ci tire, faute de stock propre.
     *
     * << Double Normale >> ne se compte pas : elle consomme deux pates normales. C'est la
     * meme pate au frigo, comptee deux fois - une seule verite, un seul compteur.
     */
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "stock_source_id")
    private VariantValue stockSource;

    /**
     * La valeur qui porte le compteur pour celle-ci : elle-meme, sa source, ou rien.
     *
     * Un seul saut : une source qui tirerait elle-meme sur une autre est refusee a
     * l'enregistrement, faute de quoi une chaine cassee ferait disparaitre la
     * decrementation sans que personne ne le voie.
     */
    @Transient
    public VariantValue stockPorteur() {
        if (stockManaged) return this;
        return stockSource != null && stockSource.isStockManaged() ? stockSource : null;
    }

    /** Ce qui s'imprime : le nom court s'il existe, le nom complet sinon. */
    @Transient
    public String ticketName() {
        return shortName == null || shortName.isBlank() ? name : shortName;
    }
}
