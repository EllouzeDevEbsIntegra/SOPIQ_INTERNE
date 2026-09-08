package com.poscaisse.service;

import com.poscaisse.domain.*;
import com.poscaisse.dto.RegisterDtos.JournalDto;
import com.poscaisse.repository.JournalRepo;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Service @RequiredArgsConstructor
public class JournalService {
    private final JournalRepo repo;

    @Transactional(propagation = Propagation.MANDATORY)
    public void record(RegisterSession session, User user, Enums.JournalEvent event, BigDecimal amount, String reference, String description) {
        RegisterJournal j = new RegisterJournal();
        if (session != null) {
            j.setSession(session);
            j.setRegister(session.getRegister());
            j.setPointOfSale(session.getRegister().getPointOfSale());
        }
        j.setUser(user);
        j.setEventType(event);
        j.setAmount(amount == null ? null : Money.r(amount));
        j.setReference(reference);
        j.setDescription(description);
        repo.save(j);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void recordForPos(PointOfSale pos, User user, Enums.JournalEvent event, BigDecimal amount, String reference, String description) {
        RegisterJournal j = new RegisterJournal();
        j.setPointOfSale(pos); j.setUser(user); j.setEventType(event); j.setAmount(amount); j.setReference(reference); j.setDescription(description);
        repo.save(j);
    }

    @Transactional(readOnly = true)
    public List<JournalDto> search(OffsetDateTime from, OffsetDateTime to, Long posId, Long registerId, Long userId, Long sessionId, String event, int limit) {
        Specification<RegisterJournal> spec = (root, q, cb) -> {
            List<Predicate> p = new ArrayList<>();
            if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            if (to != null) p.add(cb.lessThan(root.get("createdAt"), to));
            if (posId != null) p.add(cb.equal(root.get("pointOfSale").get("id"), posId));
            if (registerId != null) p.add(cb.equal(root.get("register").get("id"), registerId));
            if (userId != null) p.add(cb.equal(root.get("user").get("id"), userId));
            if (sessionId != null) p.add(cb.equal(root.get("session").get("id"), sessionId));
            if (event != null && !event.isBlank()) p.add(cb.equal(root.get("eventType"), Enums.JournalEvent.valueOf(event)));
            return cb.and(p.toArray(new Predicate[0]));
        };
        return repo.findAll(spec, PageRequest.of(0, Math.min(Math.max(limit, 1), 2000), Sort.by(Sort.Direction.DESC, "createdAt", "id")))
                .getContent().stream().map(Mappers::journal).toList();
    }
}
