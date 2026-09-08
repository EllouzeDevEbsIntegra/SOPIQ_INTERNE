package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "modifier_group") @Getter @Setter
public class ModifierGroup {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;
    private boolean required;
    private boolean multiple = true;
    private int minSelect;
    private int maxSelect;
    private int sortOrder;
    private boolean active = true;
    @OneToMany(mappedBy = "group", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("sortOrder ASC, id ASC")
    private List<Modifier> modifiers = new ArrayList<>();
}
