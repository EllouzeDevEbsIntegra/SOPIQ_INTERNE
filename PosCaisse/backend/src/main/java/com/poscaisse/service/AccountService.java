package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.AccountDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import com.poscaisse.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;

/**
 * Comptes à crédit : dette portée par les tickets encaissés « à crédit », et règlements
 * qui la diminuent. Deux natures de titulaire, tenues à l'identique :
 *
 *   CUSTOMER — un ticket à emporter porté au compte d'un client ;
 *   COURIER  — un ticket en livraison confié à un livreur, qui détient l'argent jusqu'au
 *              versement. Un ticket confié à un livreur est porté à SON compte, même si
 *              un client figure aussi dessus : sinon la même somme serait due deux fois.
 *
 * Le solde n'est jamais stocké. Il se recalcule à partir des deux mouvements — somme des
 * paiements à crédit moins somme des règlements — ce qui interdit toute dérive entre le
 * solde affiché et le détail qui le justifie.
 */
@Service @RequiredArgsConstructor
public class AccountService {
    private static final Enums.PaymentKind CREDIT = Enums.PaymentKind.CREDIT;
    private static final Enums.OrderStatus CANCELLED = Enums.OrderStatus.CANCELLED;

    private final CustomerRepo customerRepo;
    private final CourierRepo courierRepo;
    private final AccountPaymentRepo paymentRepo;
    private final PaymentRepo orderPaymentRepo;
    private final PaymentMethodRepo methodRepo;
    private final OrderLineRepo lineRepo;
    private final SessionRepo sessionRepo;
    private final TicketNumberService numbers;
    private final CurrentUser currentUser;
    private final AuditService audit;

    /** Titulaire d'un compte, vu par le service : identité seule, quelle que soit sa nature. */
    private record Party(Long id, String name, String phone) {}

    public static Enums.AccountParty party(String raw) {
        try {
            return Enums.AccountParty.valueOf(raw == null ? "CUSTOMER" : raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new BusinessException("Nature de compte inconnue : " + raw);
        }
    }

    private List<Party> parties(Enums.AccountParty p) {
        return p == Enums.AccountParty.COURIER
                ? courierRepo.findAllByOrderByNameAsc().stream().map(c -> new Party(c.getId(), c.getName(), c.getPhone())).toList()
                : customerRepo.findAllByOrderByNameAsc().stream().map(c -> new Party(c.getId(), c.getName(), c.getPhone())).toList();
    }

    private Party partyOf(Enums.AccountParty p, Long id) {
        if (p == Enums.AccountParty.COURIER) {
            Courier c = courierRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Livreur"));
            return new Party(c.getId(), c.getName(), c.getPhone());
        }
        Customer c = customerRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Client"));
        return new Party(c.getId(), c.getName(), c.getPhone());
    }

    /** Soldes de tous les comptes ; withDebtOnly limite à ceux qui doivent quelque chose. */
    @Transactional(readOnly = true)
    public List<AccountBalanceDto> balances(Enums.AccountParty p, boolean withDebtOnly) {
        boolean courier = p == Enums.AccountParty.COURIER;
        Map<Long, BigDecimal> charged = totals(courier
                ? orderPaymentRepo.creditPerCourier(CREDIT, CANCELLED)
                : orderPaymentRepo.creditPerCustomer(CREDIT, CANCELLED));
        Map<Long, BigDecimal> paid = totals(courier ? paymentRepo.paidPerCourier() : paymentRepo.paidPerCustomer());
        List<AccountBalanceDto> out = new ArrayList<>();
        for (Party party : parties(p)) {
            BigDecimal ch = charged.getOrDefault(party.id(), BigDecimal.ZERO);
            BigDecimal pa = paid.getOrDefault(party.id(), BigDecimal.ZERO);
            BigDecimal solde = Money.r(ch.subtract(pa));
            if (withDebtOnly && solde.signum() <= 0) continue;
            out.add(new AccountBalanceDto(party.id(), party.name(), party.phone(), Money.r(ch), Money.r(pa), solde));
        }
        out.sort(Comparator.comparing(AccountBalanceDto::balance).reversed());
        return out;
    }

    private Map<Long, BigDecimal> totals(List<PaymentRepo.PartyTotal> rows) {
        Map<Long, BigDecimal> m = new HashMap<>();
        for (PaymentRepo.PartyTotal r : rows) m.put(r.getPartyId(), Money.nz(r.getTotal()));
        return m;
    }

    /** Relevé d'un compte : tickets à crédit et règlements sur la période, avec les totaux. */
    @Transactional(readOnly = true)
    public StatementDto statement(Enums.AccountParty p, Long partyId, OffsetDateTime from, OffsetDateTime to) {
        Party party = partyOf(p, partyId);
        boolean courier = p == Enums.AccountParty.COURIER;
        OffsetDateTime f = from == null ? OffsetDateTime.now().minusYears(50) : from;
        OffsetDateTime t = to == null ? OffsetDateTime.now().plusYears(1) : to;

        List<SaleOrder> orders = courier
                ? orderPaymentRepo.creditOrdersCourier(partyId, CREDIT, CANCELLED, f, t)
                : orderPaymentRepo.creditOrdersCustomer(partyId, CREDIT, CANCELLED, f, t);
        List<StatementTicketDto> tickets = new ArrayList<>();
        for (SaleOrder o : orders) {
            // La quantité affichée est celle des lignes de premier niveau : additionner aussi
            // les composants d'un menu compterait deux fois le même article.
            BigDecimal qty = lineRepo.findByOrderIdAndParentLineIsNullOrderBySortOrderAsc(o.getId())
                    .stream().map(OrderLine::getQuantity).map(Money::nz)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            tickets.add(new StatementTicketDto(o.getId(), o.getTicketNumber(), o.getCreatedAt(),
                    o.getNote(), qty, Money.nz(o.getTotal())));
        }

        List<AccountPayment> raw = courier
                ? paymentRepo.findByCourierIdAndPaidAtBetweenOrderByPaidAtDesc(partyId, f, t)
                : paymentRepo.findByCustomerIdAndPaidAtBetweenOrderByPaidAtDesc(partyId, f, t);
        List<StatementPaymentDto> reglements = raw.stream()
                .map(x -> new StatementPaymentDto(x.getId(), x.getNumber(), x.getPaidAt(),
                        x.getPaymentMethod().getName(), Money.nz(x.getAmount()), x.getNote(),
                        x.getUser() == null ? null : x.getUser().getFullName()))
                .toList();

        // Les totaux du relevé portent sur la période affichée ; le solde, lui, est celui
        // du compte entier — sinon un filtre de dates ferait croire à une dette éteinte.
        BigDecimal totalTickets = tickets.stream().map(StatementTicketDto::total).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalReglements = reglements.stream().map(StatementPaymentDto::amount).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new StatementDto(p.name(), party.id(), party.name(), party.phone(),
                Money.r(totalTickets), Money.r(totalReglements), balance(p, partyId), tickets, reglements);
    }

    @Transactional(readOnly = true)
    public BigDecimal balance(Enums.AccountParty p, Long partyId) {
        boolean courier = p == Enums.AccountParty.COURIER;
        BigDecimal ch = Money.nz(courier
                ? orderPaymentRepo.creditTotalCourier(partyId, CREDIT, CANCELLED)
                : orderPaymentRepo.creditTotalCustomer(partyId, CREDIT, CANCELLED));
        BigDecimal pa = Money.nz(courier ? paymentRepo.totalPaidByCourier(partyId) : paymentRepo.totalPaidByCustomer(partyId));
        return Money.r(ch.subtract(pa));
    }

    /** Enregistre un règlement : le solde du compte diminue d'autant. */
    @Transactional
    public StatementPaymentDto pay(Enums.AccountParty p, AccountPaymentRequest r) {
        currentUser.require(Permission.CUSTOMER_CREDIT, "Vous n'avez pas la permission d'encaisser un règlement.");
        PaymentMethod m = methodRepo.findById(r.paymentMethodId()).orElseThrow(() -> BusinessException.notFound("Moyen de paiement"));
        if (m.getKind() == CREDIT)
            throw new BusinessException("Un règlement ne peut pas être encaissé « à crédit ».");
        if (r.amount() == null || r.amount().signum() <= 0) throw new BusinessException("Montant invalide.");

        BigDecimal solde = balance(p, r.partyId());
        if (r.amount().compareTo(solde) > 0)
            throw new BusinessException("Le règlement (" + Money.r(r.amount()) + ") dépasse le solde dû ("
                    + solde + "). Corrigez le montant.");

        User u = currentUser.entity();
        AccountPayment x = new AccountPayment();
        x.setNumber(numbers.nextAccountPayment(p));
        if (p == Enums.AccountParty.COURIER)
            x.setCourier(courierRepo.findById(r.partyId()).orElseThrow(() -> BusinessException.notFound("Livreur")));
        else
            x.setCustomer(customerRepo.findById(r.partyId()).orElseThrow(() -> BusinessException.notFound("Client")));
        x.setPaymentMethod(m); x.setAmount(Money.r(r.amount()));
        x.setPaidAt(OffsetDateTime.now()); x.setUser(u); x.setNote(r.note());
        // Rattaché à la session ouverte du caissier s'il y en a une : un règlement en
        // espèces doit se retrouver dans le fond de caisse compté à la clôture.
        sessionRepo.findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(u.getId(), Enums.SessionStatus.OPEN)
                .ifPresent(x::setSession);
        x = paymentRepo.saveAndFlush(x);

        audit.log("ACCOUNT_PAYMENT", "AccountPayment", x.getId(),
                p.name() + " " + partyOf(p, r.partyId()).name() + " " + x.getAmount() + " " + m.getName());
        return new StatementPaymentDto(x.getId(), x.getNumber(), x.getPaidAt(), m.getName(),
                x.getAmount(), x.getNote(), u.getFullName());
    }

    /** Annule un règlement saisi par erreur : le solde remonte d'autant. */
    @Transactional
    public void deletePayment(Long id) {
        currentUser.require(Permission.CUSTOMER_CREDIT, "Vous n'avez pas la permission de supprimer un règlement.");
        AccountPayment x = paymentRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Règlement"));
        String holder = x.getCustomer() != null ? x.getCustomer().getName() : x.getCourier().getName();
        audit.log("ACCOUNT_PAYMENT_DELETE", "AccountPayment", x.getId(), holder + " " + x.getAmount());
        paymentRepo.delete(x);
    }
}
