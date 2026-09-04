package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "category") @Getter @Setter
public class Category {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;
    private String color = "#3b82f6";
    private String icon;
    private int sortOrder;
    private boolean active = true;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "print_destination_id") private PrintDestination printDestination;
}
