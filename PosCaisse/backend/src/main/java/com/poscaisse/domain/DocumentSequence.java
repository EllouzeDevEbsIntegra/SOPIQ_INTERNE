package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "document_sequence") @Getter @Setter
public class DocumentSequence {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String scopeKey;
    private long nextValue = 1;
}
