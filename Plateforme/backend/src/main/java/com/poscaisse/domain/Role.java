package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.util.EnumSet;
import java.util.Set;

@Entity @Table(name = "role") @Getter @Setter
public class Role {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String code;
    private String name;
    private boolean systemRole;
    @ElementCollection(fetch = FetchType.EAGER, targetClass = Permission.class)
    @CollectionTable(name = "role_permission", joinColumns = @JoinColumn(name = "role_id"))
    @Column(name = "permission") @Enumerated(EnumType.STRING)
    private Set<Permission> permissions = EnumSet.noneOf(Permission.class);
}
