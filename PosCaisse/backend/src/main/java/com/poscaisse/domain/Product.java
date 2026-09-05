package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Entity @Table(name = "product") @Getter @Setter
public class Product {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String code;
    private String reference;
    private String name;
    private String shortName;
    private String description;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "category_id") private Category category;
    @Enumerated(EnumType.STRING) private Enums.ProductType productType = Enums.ProductType.SIMPLE;
    private BigDecimal price = BigDecimal.ZERO;
    private BigDecimal taxRate = BigDecimal.ZERO;
    @Column(columnDefinition = "text") private String imageUrl;
    private String color;
    private int sortOrder;
    private boolean active = true;
    private boolean available = true;
    private boolean favorite;
    private int favoriteOrder;
    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "product_print_destination", joinColumns = @JoinColumn(name = "product_id"),
            inverseJoinColumns = @JoinColumn(name = "print_destination_id"))
    private Set<PrintDestination> printDestinations = new LinkedHashSet<>();

    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("sortOrder ASC")
    private List<ProductModifierGroup> modifierGroups = new ArrayList<>();

    @OneToMany(mappedBy = "menuProduct", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("sortOrder ASC")
    private List<MenuComponent> menuComponents = new ArrayList<>();

    /**
     * Ingrédients composant le nom, dans l'ordre où ils ont été touchés :
     * « Omelette Thon Salami » ne se lit pas comme « Salami Thon Omelette ».
     *
     * Une liste et non un ensemble, donc, avec la colonne d'ordre portée par la table
     * de liaison. Ce lien sert la recherche par ingrédient en caisse ; le nom, lui,
     * reste une chaîne libre que l'on peut corriger à la main sans rien casser ici.
     */
    /**
     * Axe de déclinaison de l'article — au plus un, et souvent aucun.
     *
     * C'est cette limite à un seul axe qui évite la combinatoire : trois pâtes fois deux
     * fromages donneraient six articles à saisir et une grille tactile illisible. Quand
     * deux caractéristiques varient, la seconde se traite en articles distincts.
     */
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_id") private Variant variant;

    /** Ce que vend un appui court. Obligatoire dès qu'un axe est choisi, et à prix non nul. */
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "default_variant_value_id")
    private VariantValue defaultVariantValue;

    /**
     * Vrai : l'appui court ouvre le choix. Faux : il vend la valeur par défaut.
     *
     * Réglage par article et non par carte — sur un mlewi où neuf pâtes sur dix sont
     * normales, un appui suffit ; sur une pizza où les trois tailles se valent, mieux vaut
     * demander que de vendre une moyenne par réflexe.
     */
    private boolean askVariant;

    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<ProductVariantPrice> variantPrices = new ArrayList<>();

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "product_ingredient", joinColumns = @JoinColumn(name = "product_id"),
            inverseJoinColumns = @JoinColumn(name = "ingredient_id"))
    @OrderColumn(name = "sort_order")
    private List<Ingredient> ingredients = new ArrayList<>();
}
