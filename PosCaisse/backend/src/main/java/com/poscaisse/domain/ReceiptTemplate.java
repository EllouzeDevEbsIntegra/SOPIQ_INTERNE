package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

@Entity @Table(name = "receipt_template") @Getter @Setter
public class ReceiptTemplate {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String code;
    private String name;
    private int paperWidth = 80;
    private int fontSize = 12;
    private int marginMm = 3;
    private boolean showLogo = true;
    private String headerText;
    private String footerText;
    @Column(columnDefinition = "text") private String configJson = "{}";
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
