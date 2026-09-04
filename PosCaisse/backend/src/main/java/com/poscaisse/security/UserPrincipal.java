package com.poscaisse.security;

import com.poscaisse.domain.Permission;
import com.poscaisse.domain.User;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Getter
public class UserPrincipal {
    private final Long id;
    private final String username;
    private final String fullName;
    private final String roleCode;
    private final Set<Permission> permissions;
    private final List<GrantedAuthority> authorities;

    public UserPrincipal(User user) {
        this.id = user.getId();
        this.username = user.getUsername();
        this.fullName = user.getFullName();
        this.roleCode = user.getRole().getCode();
        this.permissions = Set.copyOf(user.getRole().getPermissions());
        List<GrantedAuthority> a = new ArrayList<>();
        a.add(new SimpleGrantedAuthority("ROLE_" + roleCode));
        permissions.forEach(p -> a.add(new SimpleGrantedAuthority(p.name())));
        this.authorities = List.copyOf(a);
    }

    public boolean has(Permission p) { return permissions.contains(p); }
}
