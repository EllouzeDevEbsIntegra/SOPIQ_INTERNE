package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "menu_component") @Getter @Setter
public class MenuComponent {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "menu_product_id") private Product menuProduct;
    private String name;
    private int quantity = 1;
    private int sortOrder;
    @OneToMany(mappedBy = "component", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<MenuComponentProduct> options = new ArrayList<>();
}
