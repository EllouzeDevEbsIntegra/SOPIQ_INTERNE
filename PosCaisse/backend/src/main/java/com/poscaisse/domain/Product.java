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
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "product_ingredient", joinColumns = @JoinColumn(name = "product_id"),
            inverseJoinColumns = @JoinColumn(name = "ingredient_id"))
    @OrderColumn(name = "sort_order")
    private List<Ingredient> ingredients = new ArrayList<>();
}
