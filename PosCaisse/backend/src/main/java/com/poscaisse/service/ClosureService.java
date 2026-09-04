package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.RegisterDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import com.poscaisse.security.CurrentUser;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.*;

@Service @RequiredArgsConstructor
public class ClosureService {
    private static final ZoneId TZ = ZoneId.of("Africa/Tunis");
    private final DailyClosureRepo closureRepo;
    private final SessionRepo sessionRepo;
    private final PointOfSaleRepo posRepo;
    private final OrderRepo orderRepo;
    private final RegisterSessionService sessions;
    private final CurrentUser currentUser;
    private final AuditService audit;
    private final JournalService journal;
    private final ObjectMapper om;

    @Transactional(readOnly = true)
    public DailyPreview preview(Long posId, LocalDate date) {
        OffsetDateTime from = date.atStartOfDay(TZ).toOffsetDateTime();
        OffsetDateTime to = date.plusDays(1).atStartOfDay(TZ).toOffsetDateTime();
        List<RegisterSession> sess = sessionRepo.findByRegisterPointOfSaleIdAndOpenedAtBetween(posId, from, to);
        BigDecimal revenue = BigDecimal.ZERO, cash = BigDecimal.ZERO, card = BigDecimal.ZERO, other = BigDecimal.ZERO, disc = BigDecimal.ZERO,
                cancelsTotal = BigDecimal.ZERO, refunds = BigDecimal.ZERO, in = BigDecimal.ZERO, out = BigDecimal.ZERO, diff = BigDecimal.ZERO;
        int tickets = 0, cancels = 0, open = 0;
        Map<String, Map<String, Object>> byRegister = new LinkedHashMap<>();
        Map<String, Map<String, Object>> byCashier = new LinkedHashMap<>();
        Map<String, BigDecimal> byMethod = new LinkedHashMap<>();
        for (RegisterSession s : sess) {
            SessionSummary sum = sessions.computeSummary(s);
            if (s.getStatus() == Enums.SessionStatus.OPEN) open++;
            revenue = revenue.add(sum.revenue()); cash = cash.add(sum.cashSales()); card = card.add(sum.cardSales()); other = other.add(sum.otherSales());
            disc = disc.add(sum.discounts()); refunds = refunds.add(sum.cashRefunds()).add(sum.otherRefunds()); in = in.add(sum.cashIn()); out = out.add(sum.cashOut());
            tickets += sum.ticketsCount(); cancels += sum.cancellationsCount();
            if (s.getCashDifference() != null) diff = diff.add(s.getCashDifference());
            sum.byMethod().forEach((k, v) -> byMethod.merge(k, v, BigDecimal::add));
            for (SaleOrder o : orderRepo.findBySessionIdOrderByPaidAtDesc(s.getId())) {
                if (o.getStatus() == Enums.OrderStatus.CANCELLED) { cancelsTotal = cancelsTotal.add(o.getTotal()); continue; }
                if (o.getStatus() == Enums.OrderStatus.HELD) continue;
                BigDecimal net = o.getTotal().subtract(Money.nz(o.getRefundedTotal()));
                bump(byRegister, s.getRegister().getName(), net);
                bump(byCashier, o.getCashier().getFullName(), net);
            }
        }
        BigDecimal avg = tickets == 0 ? BigDecimal.ZERO : Money.r(revenue.divide(BigDecimal.valueOf(tickets), 6, java.math.RoundingMode.HALF_UP));
        List<Map<String, Object>> methods = new ArrayList<>();
        byMethod.forEach((k, v) -> methods.add(Map.of("name", k, "amount", Money.r(v))));
        return new DailyPreview(date, posId, Money.r(revenue), tickets, avg, Money.r(cash), Money.r(card), Money.r(other), Money.r(disc), cancels,
                Money.r(cancelsTotal), Money.r(refunds), Money.r(in), Money.r(out), Money.r(diff), new ArrayList<>(byRegister.values()),
                new ArrayList<>(byCashier.values()), methods, sess.stream().map(Mappers::session).toList(),
                closureRepo.findByPointOfSaleIdAndBusinessDate(posId, date).isPresent(), open);
    }

    private static void bump(Map<String, Map<String, Object>> m, String key, BigDecimal amount) {
        Map<String, Object> row = m.computeIfAbsent(key, k -> new LinkedHashMap<>(Map.of("name", k, "amount", BigDecimal.ZERO, "tickets", 0)));
        row.put("amount", ((BigDecimal) row.get("amount")).add(amount));
        row.put("tickets", ((Integer) row.get("tickets")) + 1);
    }

    @Transactional
    public DailyClosureDto close(DailyClosureRequest req) {
        currentUser.require(Permission.DAILY_CLOSE, "La clôture journalière nécessite l'autorisation d'un manager.");
        PointOfSale pos = posRepo.findById(req.pointOfSaleId()).orElseThrow(() -> BusinessException.notFound("Point de vente"));
        closureRepo.findByPointOfSaleIdAndBusinessDate(pos.getId(), req.businessDate()).ifPresent(c -> { throw BusinessException.conflict("La journée du " + req.businessDate() + " est déjà clôturée."); });
        DailyPreview p = preview(pos.getId(), req.businessDate());
        if (p.openSessions() > 0) throw new BusinessException("Il reste " + p.openSessions() + " caisse(s) ouverte(s) : clôturez-les avant la clôture journalière.");
        DailyClosure c = new DailyClosure();
        c.setPointOfSale(pos); c.setBusinessDate(req.businessDate()); c.setClosedBy(currentUser.entity());
        c.setRevenue(p.revenue()); c.setTicketsCount(p.ticketsCount()); c.setAverageTicket(p.averageTicket()); c.setCashTotal(p.cashTotal()); c.setCardTotal(p.cardTotal());
        c.setOtherTotal(p.otherTotal()); c.setDiscountsTotal(p.discountsTotal()); c.setCancellationsCount(p.cancellationsCount()); c.setCancellationsTotal(p.cancellationsTotal());
        c.setRefundsTotal(p.refundsTotal()); c.setCashIn(p.cashIn()); c.setCashOut(p.cashOut()); c.setCashDifference(p.cashDifference()); c.setNote(req.note());
        try { c.setDetailsJson(om.writeValueAsString(Map.of("byRegister", p.byRegister(), "byCashier", p.byCashier(), "byMethod", p.byMethod(), "sessions", p.sessions().stream().map(SessionDto::id).toList()))); } catch (Exception ignored) {}
        c = closureRepo.save(c);
        journal.recordForPos(pos, c.getClosedBy(), Enums.JournalEvent.DAILY_CLOSE, c.getRevenue(), "J" + c.getId(), "Clôture journalière " + req.businessDate() + " — CA " + c.getRevenue());
        audit.log("DAILY_CLOSE", "DailyClosure", c.getId(), req.businessDate() + " CA=" + c.getRevenue() + " tickets=" + c.getTicketsCount());
        return dto(c);
    }

    @Transactional(readOnly = true)
    public List<DailyClosureDto> list() { return closureRepo.findAllByOrderByBusinessDateDesc().stream().map(this::dto).toList(); }

    private DailyClosureDto dto(DailyClosure c) {
        Object details = null;
        try { if (c.getDetailsJson() != null) details = om.readValue(c.getDetailsJson(), new TypeReference<Map<String, Object>>() {}); } catch (Exception ignored) {}
        return new DailyClosureDto(c.getId(), c.getPointOfSale().getId(), c.getPointOfSale().getName(), c.getBusinessDate(), c.getClosedBy().getFullName(), c.getClosedAt(),
                c.getRevenue(), c.getTicketsCount(), c.getAverageTicket(), c.getCashTotal(), c.getCardTotal(), c.getOtherTotal(), c.getDiscountsTotal(),
                c.getCancellationsCount(), c.getCancellationsTotal(), c.getRefundsTotal(), c.getCashIn(), c.getCashOut(), c.getCashDifference(), c.getNote(), details);
    }
}
