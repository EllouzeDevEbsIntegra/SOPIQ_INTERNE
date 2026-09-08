package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

@Entity @Table(name = "audit_log") @Getter @Setter
public class AuditLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private Long userId;
    private String username;
    private String action;
    private String entityType;
    private String entityId;
    private String details;
    private String ipAddress;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
