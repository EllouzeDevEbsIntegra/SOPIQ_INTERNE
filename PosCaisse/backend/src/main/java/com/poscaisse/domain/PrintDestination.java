package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "print_destination") @Getter @Setter
public class PrintDestination {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String code;
    private String name;
    @Enumerated(EnumType.STRING) private Enums.DestinationKind kind = Enums.DestinationKind.PREP;
    private int copies = 1;
    private boolean showPrices;
    private int sortOrder;
    private boolean active = true;
}
