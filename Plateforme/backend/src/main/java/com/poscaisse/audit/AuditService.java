package com.poscaisse.audit;

import com.poscaisse.domain.AuditLog;
import com.poscaisse.repository.AuditRepo;
import com.poscaisse.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class AuditService {
    private final AuditRepo auditRepo;

    @Transactional(propagation = Propagation.REQUIRED)
    public void log(String action, String entityType, Object entityId, String details) {
        AuditLog a = new AuditLog();
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserPrincipal p) {
            a.setUserId(p.getId());
            a.setUsername(p.getUsername());
        }
        a.setAction(action);
        a.setEntityType(entityType);
        a.setEntityId(entityId == null ? null : String.valueOf(entityId));
        a.setDetails(details == null ? null : (details.length() > 1000 ? details.substring(0, 1000) : details));
        auditRepo.save(a);
    }

    @Transactional(propagation = Propagation.REQUIRED)
    public void logAs(Long userId, String username, String action, String entityType, Object entityId, String details) {
        AuditLog a = new AuditLog();
        a.setUserId(userId);
        a.setUsername(username);
        a.setAction(action);
        a.setEntityType(entityType);
        a.setEntityId(entityId == null ? null : String.valueOf(entityId));
        a.setDetails(details);
        auditRepo.save(a);
    }
}
