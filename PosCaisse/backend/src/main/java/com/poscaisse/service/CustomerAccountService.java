package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.CustomerAccountDtos.*;
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
 * Comptes clients : dette portée par les tickets encaissés « à crédit », et règlements
 * qui la diminuent.
 *
 * Le solde n'est jamais stocké. Il se recalcule à partir des deux mouvements — somme des
 * paiements à crédit moins somme des règlements — ce qui interdit toute dérive entre le
 * solde affiché et le détail qui le justifie. Avec quelques centaines de clients, le coût
 * est négligeable, et les deux totaux se lisent en une requête groupée chacun.
 */
@Service @RequiredArgsConstructor
public class CustomerAccountService {
    private static final Enums.PaymentKind CREDIT = Enums.PaymentKind.CREDIT;
    private static final Enums.OrderStatus CANCELLED = Enums.OrderStatus.CANCELLED;

    private final CustomerRepo customerRepo;
    private final CustomerPaymentRepo paymentRepo;
    private final PaymentRepo orderPaymentRepo;
    private final PaymentMethodRepo methodRepo;
    private final OrderLineRepo lineRepo;
    private final SessionRepo sessionRepo;
    private final TicketNumberService numbers;
    private final CurrentUser currentUser;
    private final AuditService audit;

    /** Soldes de tous les clients ; withDebtOnly limite à ceux qui doivent quelque chose. */
    @Transactional(readOnly = true)
    public List<CustomerBalanceDto> balances(boolean withDebtOnly) {
        Map<Long, BigDecimal> charged = totals(orderPaymentRepo.creditTotals(CREDIT, CANCELLED));
        Map<Long, BigDecimal> paid = totals(paymentRepo.totalPaidByCustomer());
        List<CustomerBalanceDto> out = new ArrayList<>();
        for (Customer c : customerRepo.findAll()) {
            BigDecimal ch = charged.getOrDefault(c.getId(), BigDecimal.ZERO);
            BigDecimal pa = paid.getOrDefault(c.getId(), BigDecimal.ZERO);
            BigDecimal solde = Money.r(ch.subtract(pa));
            if (withDebtOnly && solde.signum() <= 0) continue;
            out.add(new CustomerBalanceDto(c.getId(), c.getName(), c.getPhone(), Money.r(ch), Money.r(pa), solde));
        }
        out.sort(Comparator.comparing(CustomerBalanceDto::balance).reversed());
        return out;
    }

    private Map<Long, BigDecimal> totals(List<PaymentRepo.CustomerTotal> rows) {
        Map<Long, BigDecimal> m = new HashMap<>();
        for (PaymentRepo.CustomerTotal r : rows) m.put(r.getCustomerId(), Money.nz(r.getTotal()));
        return m;
    }

    /** Relevé d'un client : tickets à crédit et règlements sur la période, avec les totaux. */
    @Transactional(readOnly = true)
    public StatementDto statement(Long customerId, OffsetDateTime from, OffsetDateTime to) {
        Customer c = customerRepo.findById(customerId).orElseThrow(() -> BusinessException.notFound("Client"));
        OffsetDateTime f = from == null ? OffsetDateTime.now().minusYears(50) : from;
        OffsetDateTime t = to == null ? OffsetDateTime.now().plusYears(1) : to;

        List<StatementTicketDto> tickets = new ArrayList<>();
        for (SaleOrder o : orderPaymentRepo.creditOrders(customerId, CREDIT, CANCELLED, f, t)) {
            // La quantité affichée est celle des lignes de premier niveau : additionner aussi
            // les composants d'un menu compterait deux fois le même article.
            BigDecimal qty = lineRepo.findByOrderIdAndParentLineIsNullOrderBySortOrderAsc(o.getId())
                    .stream().map(OrderLine::getQuantity).map(Money::nz)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            tickets.add(new StatementTicketDto(o.getId(), o.getTicketNumber(), o.getCreatedAt(),
                    o.getNote(), qty, Money.nz(o.getTotal())));
        }

        List<StatementPaymentDto> reglements = paymentRepo
                .findByCustomerIdAndPaidAtBetweenOrderByPaidAtDesc(customerId, f, t).stream()
                .map(p -> new StatementPaymentDto(p.getId(), p.getNumber(), p.getPaidAt(),
                        p.getPaymentMethod().getName(), Money.nz(p.getAmount()), p.getNote(),
                        p.getUser() == null ? null : p.getUser().getFullName()))
                .toList();

        // Les totaux du relevé portent sur la période affichée ; le solde, lui, est celui
        // du compte entier — sinon un filtre de dates ferait croire à une dette éteinte.
        BigDecimal totalTickets = tickets.stream().map(StatementTicketDto::total).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalReglements = reglements.stream().map(StatementPaymentDto::amount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal solde = balance(customerId);
        return new StatementDto(c.getId(), c.getName(), c.getPhone(),
                Money.r(totalTickets), Money.r(totalReglements), solde, tickets, reglements);
    }

    @Transactional(readOnly = true)
    public BigDecimal balance(Long customerId) {
        BigDecimal ch = Money.nz(orderPaymentRepo.creditTotal(customerId, CREDIT, CANCELLED));
        BigDecimal pa = Money.nz(paymentRepo.totalPaid(customerId));
        return Money.r(ch.subtract(pa));
    }

    /** Enregistre un règlement : le solde du client diminue d'autant. */
    @Transactional
    public StatementPaymentDto pay(CustomerPaymentRequest r) {
        currentUser.require(Permission.CUSTOMER_CREDIT, "Vous n'avez pas la permission d'encaisser un règlement client.");
        Customer c = customerRepo.findById(r.customerId()).orElseThrow(() -> BusinessException.notFound("Client"));
        PaymentMethod m = methodRepo.findById(r.paymentMethodId()).orElseThrow(() -> BusinessException.notFound("Moyen de paiement"));
        if (m.getKind() == CREDIT)
            throw new BusinessException("Un règlement ne peut pas être encaissé « à crédit ».");
        if (r.amount() == null || r.amount().signum() <= 0) throw new BusinessException("Montant invalide.");

        BigDecimal solde = balance(r.customerId());
        if (r.amount().compareTo(solde) > 0)
            throw new BusinessException("Le règlement (" + Money.r(r.amount()) + ") dépasse le solde dû ("
                    + solde + "). Corrigez le montant.");

        User u = currentUser.entity();
        CustomerPayment p = new CustomerPayment();
        p.setNumber(numbers.nextCustomerPayment());
        p.setCustomer(c); p.setPaymentMethod(m); p.setAmount(Money.r(r.amount()));
        p.setPaidAt(OffsetDateTime.now()); p.setUser(u); p.setNote(r.note());
        // Rattaché à la session ouverte du caissier s'il y en a une : un règlement en
        // espèces doit se retrouver dans le fond de caisse compté à la clôture.
        sessionRepo.findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(u.getId(), Enums.SessionStatus.OPEN)
                .ifPresent(p::setSession);
        p = paymentRepo.saveAndFlush(p);

        audit.log("CUSTOMER_PAYMENT", "CustomerPayment", p.getId(),
                c.getName() + " " + p.getAmount() + " " + m.getName());
        return new StatementPaymentDto(p.getId(), p.getNumber(), p.getPaidAt(), m.getName(),
                p.getAmount(), p.getNote(), u.getFullName());
    }

    /** Annule un règlement saisi par erreur : le solde remonte d'autant. */
    @Transactional
    public void deletePayment(Long id) {
        currentUser.require(Permission.CUSTOMER_CREDIT, "Vous n'avez pas la permission de supprimer un règlement.");
        CustomerPayment p = paymentRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Règlement"));
        audit.log("CUSTOMER_PAYMENT_DELETE", "CustomerPayment", p.getId(),
                p.getCustomer().getName() + " " + p.getAmount());
        paymentRepo.delete(p);
    }
}
