package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.RegisterDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import com.poscaisse.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;

@Service @RequiredArgsConstructor
public class RegisterSessionService {
    private final SessionRepo sessionRepo;
    private final RegisterRepo registerRepo;
    private final PaymentRepo paymentRepo;
    private final RefundRepo refundRepo;
    private final CashMovementRepo movementRepo;
    private final OrderRepo orderRepo;
    private final CurrentUser currentUser;
    private final AuditService audit;
    private final JournalService journal;

    @Transactional(readOnly = true)
    public List<RegisterStatusDto> registers(Long posId) {
        List<Register> regs = posId == null ? registerRepo.findAllByOrderByCodeAsc() : registerRepo.findByPointOfSaleIdOrderByCodeAsc(posId);
        return regs.stream().filter(Register::isActive).map(r -> new RegisterStatusDto(r.getId(), r.getCode(), r.getName(), r.getPointOfSale().getId(),
                r.getPointOfSale().getName(), r.isActive(), Mappers.session(sessionRepo.findFirstByRegisterIdAndStatus(r.getId(), Enums.SessionStatus.OPEN).orElse(null)))).toList();
    }

    @Transactional(readOnly = true)
    public SessionDto current() {
        return sessionRepo.findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(currentUser.id(), Enums.SessionStatus.OPEN).map(Mappers::session).orElse(null);
    }

    @Transactional(readOnly = true)
    public SessionDto get(Long id) { return Mappers.session(sessionRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Session"))); }

    @Transactional(readOnly = true)
    public List<SessionDto> search(OffsetDateTime from, OffsetDateTime to) {
        org.springframework.data.jpa.domain.Specification<RegisterSession> spec = (root, q, cb) -> {
            List<jakarta.persistence.criteria.Predicate> p = new ArrayList<>();
            if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("openedAt"), from));
            if (to != null) p.add(cb.lessThan(root.get("openedAt"), to));
            return cb.and(p.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
        return sessionRepo.findAll(spec, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "openedAt")).stream().map(Mappers::session).toList();
    }

    @Transactional
    public SessionDto open(OpenSessionRequest req) {
        currentUser.require(Permission.REGISTER_OPEN, "Vous n'avez pas la permission d'ouvrir une caisse.");
        Register reg = registerRepo.findById(req.registerId()).orElseThrow(() -> BusinessException.notFound("Caisse"));
        if (!reg.isActive()) throw new BusinessException("Cette caisse est désactivée.");
        if (req.openingFloat().signum() < 0) throw new BusinessException("Le fond de caisse ne peut pas être négatif.");
        sessionRepo.findFirstByRegisterIdAndStatus(reg.getId(), Enums.SessionStatus.OPEN).ifPresent(s -> {
            throw BusinessException.conflict("Cette caisse possède déjà une session ouverte (par " + s.getOpenedBy().getFullName() + ").");
        });
        User me = currentUser.entity();
        sessionRepo.findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(me.getId(), Enums.SessionStatus.OPEN).ifPresent(s -> {
            throw BusinessException.conflict("Vous avez déjà une session ouverte sur " + s.getRegister().getName() + ". Clôturez-la d'abord.");
        });
        RegisterSession s = new RegisterSession();
        s.setRegister(reg); s.setOpenedBy(me); s.setOpeningFloat(Money.r(req.openingFloat()));
        s = sessionRepo.saveAndFlush(s);
        journal.record(s, me, Enums.JournalEvent.SESSION_OPEN, s.getOpeningFloat(), "S" + s.getId(), "Ouverture " + reg.getName() + " — fond " + s.getOpeningFloat());
        audit.log("SESSION_OPEN", "RegisterSession", s.getId(), reg.getCode() + " fond=" + s.getOpeningFloat());
        return Mappers.session(s);
    }

    @Transactional(readOnly = true)
    public SessionSummary summary(Long sessionId) {
        RegisterSession s = sessionRepo.findById(sessionId).orElseThrow(() -> BusinessException.notFound("Session"));
        return computeSummary(s);
    }

    public SessionSummary computeSummary(RegisterSession s) {
        BigDecimal cash = BigDecimal.ZERO, card = BigDecimal.ZERO, other = BigDecimal.ZERO;
        Map<String, BigDecimal> byMethod = new LinkedHashMap<>();
        for (Payment p : paymentRepo.findBySessionId(s.getId())) {
            if (p.getOrder().getStatus() == Enums.OrderStatus.HELD) continue;
            BigDecimal net = p.getAmount(); // amount is already the applied part (change excluded)
            byMethod.merge(p.getPaymentMethod().getName(), net, BigDecimal::add);
            switch (p.getPaymentMethod().getKind()) {
                case CASH -> cash = cash.add(net);
                case CARD -> card = card.add(net);
                default -> other = other.add(net);
            }
        }
        BigDecimal cashRefunds = BigDecimal.ZERO, otherRefunds = BigDecimal.ZERO;
        for (Refund r : refundRepo.findBySessionId(s.getId())) {
            if (r.getPaymentMethod().getKind() == Enums.PaymentKind.CASH) cashRefunds = cashRefunds.add(r.getAmount());
            else otherRefunds = otherRefunds.add(r.getAmount());
        }
        BigDecimal in = BigDecimal.ZERO, out = BigDecimal.ZERO;
        for (CashMovement m : movementRepo.findBySessionIdOrderByCreatedAtAsc(s.getId())) {
            if (m.getMovementType() == Enums.MovementType.IN) in = in.add(m.getAmount()); else out = out.add(m.getAmount());
        }
        List<SaleOrder> orders = orderRepo.findBySessionIdOrderByPaidAtDesc(s.getId());
        int tickets = 0, cancels = 0;
        BigDecimal revenue = BigDecimal.ZERO, discounts = BigDecimal.ZERO;
        for (SaleOrder o : orders) {
            if (o.getStatus() == Enums.OrderStatus.HELD) continue;
            if (o.getStatus() == Enums.OrderStatus.CANCELLED) { cancels++; continue; }
            tickets++;
            revenue = revenue.add(o.getTotal()).subtract(Money.nz(o.getRefundedTotal()));
            discounts = discounts.add(o.getDiscountAmount()).add(o.getLineDiscountTotal());
        }
        BigDecimal expected = Money.r(s.getOpeningFloat().add(cash).subtract(cashRefunds).add(in).subtract(out));
        return new SessionSummary(s.getId(), s.getOpeningFloat(), Money.r(cash), Money.r(card), Money.r(other), Money.r(cashRefunds), Money.r(otherRefunds),
                Money.r(in), Money.r(out), expected, tickets, cancels, Money.r(revenue), Money.r(discounts), byMethod);
    }

    @Transactional
    public SessionDto close(Long sessionId, CloseSessionRequest req) {
        currentUser.require(Permission.REGISTER_CLOSE, "Vous n'avez pas la permission de clôturer une caisse.");
        RegisterSession s = sessionRepo.findById(sessionId).orElseThrow(() -> BusinessException.notFound("Session"));
        if (s.getStatus() == Enums.SessionStatus.CLOSED) throw BusinessException.conflict("Cette session est déjà clôturée.");
        User me = currentUser.entity();
        if (!s.getOpenedBy().getId().equals(me.getId()) && !currentUser.has(Permission.DAILY_CLOSE))
            throw BusinessException.forbidden("Seul le caissier ayant ouvert la caisse (ou un manager) peut la clôturer.");
        long held = orderRepo.countBySessionIdAndStatusIn(s.getId(), List.of(Enums.OrderStatus.HELD));
        if (held > 0) throw new BusinessException("Il reste " + held + " commande(s) en attente sur cette session. Encaissez-les ou abandonnez-les avant la clôture.");
        if (req.countedCash().signum() < 0) throw new BusinessException("Le montant compté ne peut pas être négatif.");
        SessionSummary sum = computeSummary(s);
        s.setCashSales(sum.cashSales()); s.setCardSales(sum.cardSales()); s.setOtherSales(sum.otherSales());
        s.setCashRefunds(sum.cashRefunds()); s.setCashIn(sum.cashIn()); s.setCashOut(sum.cashOut());
        s.setExpectedCash(sum.expectedCash()); s.setCountedCash(Money.r(req.countedCash()));
        s.setCashDifference(Money.r(req.countedCash().subtract(sum.expectedCash())));
        s.setTicketsCount(sum.ticketsCount()); s.setRevenue(sum.revenue());
        s.setClosingNote(req.note()); s.setClosedBy(me); s.setClosedAt(OffsetDateTime.now()); s.setStatus(Enums.SessionStatus.CLOSED);
        s = sessionRepo.saveAndFlush(s);
        journal.record(s, me, Enums.JournalEvent.SESSION_CLOSE, s.getCountedCash(), "S" + s.getId(),
                "Clôture " + s.getRegister().getName() + " — théorique " + s.getExpectedCash() + ", réel " + s.getCountedCash() + ", écart " + s.getCashDifference());
        audit.log("SESSION_CLOSE", "RegisterSession", s.getId(), "théorique=" + s.getExpectedCash() + " réel=" + s.getCountedCash() + " écart=" + s.getCashDifference());
        return Mappers.session(s);
    }

    @Transactional
    public CashMovementDto addMovement(Long sessionId, CashMovementRequest req) {
        currentUser.require(Permission.CASH_MOVEMENT, "Vous n'avez pas la permission d'effectuer un mouvement de caisse.");
        RegisterSession s = sessionRepo.findById(sessionId).orElseThrow(() -> BusinessException.notFound("Session"));
        if (s.getStatus() != Enums.SessionStatus.OPEN) throw BusinessException.conflict("La session de caisse est clôturée.");
        if (req.amount().signum() <= 0) throw new BusinessException("Le montant doit être supérieur à zéro.");
        Enums.MovementType type = Enums.MovementType.valueOf(req.type().toUpperCase());
        CashMovement m = new CashMovement();
        m.setSession(s); m.setUser(currentUser.entity()); m.setMovementType(type); m.setReason(req.reason().trim());
        m.setAmount(Money.r(req.amount())); m.setComment(req.comment());
        m = movementRepo.save(m);
        journal.record(s, m.getUser(), type == Enums.MovementType.IN ? Enums.JournalEvent.CASH_IN : Enums.JournalEvent.CASH_OUT,
                m.getAmount(), "M" + m.getId(), (type == Enums.MovementType.IN ? "Entrée : " : "Sortie : ") + m.getReason() + (m.getComment() == null ? "" : " — " + m.getComment()));
        audit.log("CASH_" + type.name(), "CashMovement", m.getId(), m.getReason() + " " + m.getAmount());
        return Mappers.movement(m);
    }

    @Transactional(readOnly = true)
    public List<CashMovementDto> movements(Long sessionId) {
        return movementRepo.findBySessionIdOrderByCreatedAtAsc(sessionId).stream().map(Mappers::movement).toList();
    }

    public RegisterSession requireOpenSession(Long registerId) {
        return sessionRepo.findFirstByRegisterIdAndStatus(registerId, Enums.SessionStatus.OPEN)
                .orElseThrow(() -> BusinessException.conflict("Aucune session ouverte sur cette caisse. Ouvrez la caisse avant de vendre."));
    }
}
