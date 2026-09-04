package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.OrderDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.printing.PrintService;
import com.poscaisse.repository.*;
import com.poscaisse.security.CurrentUser;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor @Slf4j
public class OrderService {
    private static final BigDecimal TOLERANCE = new BigDecimal("0.0005");

    private final OrderRepo orderRepo;
    private final ProductRepo productRepo;
    private final ModifierRepo modifierRepo;
    private final PaymentMethodRepo paymentMethodRepo;
    private final RegisterRepo registerRepo;
    private final CustomerRepo customerRepo;
    private final RefundRepo refundRepo;
    private final SessionRepo sessionRepo;
    private final SequenceRepo sequenceRepo;
    private final PrintJobRepo printJobRepo;
    private final CurrentUser currentUser;
    private final PricingService pricing;
    private final TicketNumberService ticketNumbers;
    private final RegisterSessionService sessions;
    private final JournalService journal;
    private final PrintService printService;
    private final SettingsService settings;
    private final AuditService audit;

    // =================== CHECKOUT ===================
    @Transactional
    public OrderDto checkout(CheckoutRequest req) {
        currentUser.require(Permission.SELL, "Vous n'avez pas la permission de vendre.");
        // Idempotency: a double tap on VALIDER re-sends the same clientRef -> return the existing sale.
        Optional<SaleOrder> existing = orderRepo.findByClientRef(req.clientRef());
        if (existing.isPresent()) return toDto(existing.get());

        User me = currentUser.entity();
        Register reg = registerRepo.findById(req.registerId()).orElseThrow(() -> BusinessException.notFound("Caisse"));
        RegisterSession session = sessions.requireOpenSession(reg.getId());
        SaleOrder o = new SaleOrder();
        o.setClientRef(req.clientRef());
        fillOrder(o, reg, session, me, req.serviceMode(), req.customerId(), req.customerName(), req.customerPhone(), req.note(),
                req.discountPercent(), req.discountAmount(), req.lines());
        pricing.computeOrder(o);
        applyPayments(o, req.payments(), session);
        o.setStatus(Enums.OrderStatus.PAID);
        o.setPaidAt(OffsetDateTime.now());
        o.setTicketNumber(ticketNumbers.next(reg.getPointOfSale(), reg.getCode()));
        if (req.heldOrderId() != null) {
            orderRepo.findById(req.heldOrderId()).filter(h -> h.getStatus() == Enums.OrderStatus.HELD).ifPresent(h -> {
                o.setHeldRef(h.getHeldRef());
                orderRepo.delete(h);
            });
        }
        SaleOrder saved = orderRepo.saveAndFlush(o);
        journal.record(session, me, Enums.JournalEvent.SALE, saved.getTotal(), saved.getTicketNumber(),
                "Vente " + saved.getTicketNumber() + " (" + saved.getLines().stream().filter(l -> l.getParentLine() == null).count() + " lignes)");
        for (Payment p : saved.getPayments())
            journal.record(session, me, Enums.JournalEvent.PAYMENT, p.getAmount(), saved.getTicketNumber(), "Paiement " + p.getPaymentMethod().getName()
                    + (p.getChangeGiven().signum() > 0 ? " (rendu " + p.getChangeGiven() + ")" : ""));
        audit.log("SALE", "Order", saved.getId(), saved.getTicketNumber() + " total=" + saved.getTotal() + " paiements=" +
                saved.getPayments().stream().map(p -> p.getPaymentMethod().getCode() + ":" + p.getAmount()).collect(Collectors.joining(",")));
        if (saved.getDiscountAmount().signum() > 0 || saved.getLineDiscountTotal().signum() > 0)
            audit.log("DISCOUNT", "Order", saved.getId(), "remise commande=" + saved.getDiscountAmount() + " remises lignes=" + saved.getLineDiscountTotal());
        List<PrintJob> jobs = printService.createJobs(saved, false);
        return Mappers.order(saved, List.of(), jobs);
    }

    /** Price a cart without saving (used for the live total when needed and by tests). */
    @Transactional(readOnly = true)
    public PriceQuote quote(CartRequest req) {
        Register reg = registerRepo.findById(req.registerId()).orElseThrow(() -> BusinessException.notFound("Caisse"));
        SaleOrder o = new SaleOrder();
        fillOrder(o, reg, null, currentUser.entity(), req.serviceMode(), null, null, null, null, req.discountPercent(), req.discountAmount(), req.lines());
        pricing.computeOrder(o);
        return new PriceQuote(o.getSubtotal(), o.getLineDiscountTotal(), o.getDiscountAmount(), o.getTaxTotal(), o.getTotal(),
                o.getLines().stream().filter(l -> l.getParentLine() == null).map(Mappers::line).toList());
    }

    private void fillOrder(SaleOrder o, Register reg, RegisterSession session, User me, String serviceMode, Long customerId, String customerName,
                           String customerPhone, String note, BigDecimal discountPercent, BigDecimal discountAmount, List<CartLineRequest> lines) {
        o.setCompany(reg.getPointOfSale().getCompany());
        o.setPointOfSale(reg.getPointOfSale());
        o.setRegister(reg);
        o.setSession(session);
        o.setCashier(me);
        Enums.ServiceMode mode = serviceMode == null ? Enums.ServiceMode.valueOf(settings.get(SettingsService.DEFAULT_SERVICE_MODE)) : Enums.ServiceMode.valueOf(serviceMode);
        Set<String> enabledModes = Arrays.stream(settings.get(SettingsService.SERVICE_MODES).split(",")).map(String::trim).collect(Collectors.toSet());
        if (!enabledModes.contains(mode.name())) throw new BusinessException("Ce mode de service est désactivé.");
        o.setServiceMode(mode);
        if (customerId != null) customerRepo.findById(customerId).ifPresent(c -> { o.setCustomer(c); if (customerName == null) o.setCustomerName(c.getName()); if (customerPhone == null) o.setCustomerPhone(c.getPhone()); });
        if (customerName != null && !customerName.isBlank()) o.setCustomerName(customerName.trim());
        if (customerPhone != null && !customerPhone.isBlank()) o.setCustomerPhone(customerPhone.trim());
        o.setNote(note);
        checkDiscount(discountPercent, discountAmount, null);
        o.setDiscountPercent(Money.nz(discountPercent));
        o.setDiscountAmount(Money.nz(discountAmount));
        o.getLines().clear();
        int i = 0;
        for (CartLineRequest lr : lines) {
            OrderLine l = buildLine(o, lr, null, i++);
            o.getLines().add(l);
        }
    }

    private OrderLine buildLine(SaleOrder o, CartLineRequest lr, OrderLine parent, int sortOrder) {
        Product p = productRepo.findById(lr.productId()).orElseThrow(() -> BusinessException.notFound("Produit #" + lr.productId()));
        if (!p.isActive()) throw new BusinessException("Le produit « " + p.getName() + " » n'est plus au catalogue.");
        if (!p.isAvailable()) throw new BusinessException("Le produit « " + p.getName() + " » est indisponible.");
        if (lr.quantity() == null || lr.quantity().signum() <= 0) throw new BusinessException("Quantité invalide pour « " + p.getName() + " ».");
        OrderLine l = new OrderLine();
        l.setOrder(o); l.setParentLine(parent); l.setProduct(p); l.setCategory(p.getCategory());
        l.setProductCode(p.getCode()); l.setProductName(p.getName()); l.setQuantity(lr.quantity()); l.setSortOrder(sortOrder);
        l.setTaxRate(p.getTaxRate()); l.setNote(lr.note());
        BigDecimal basePrice = parent == null ? p.getPrice() : componentDelta(parent.getProduct(), p);
        l.setOriginalUnitPrice(basePrice);
        if (lr.unitPrice() != null && lr.unitPrice().compareTo(basePrice) != 0) {
            if (!currentUser.has(Permission.PRICE_EDIT)) throw BusinessException.forbidden("Vous n'avez pas la permission de modifier un prix.");
            if (lr.unitPrice().signum() < 0) throw new BusinessException("Prix invalide.");
            l.setUnitPrice(Money.r(lr.unitPrice()));
            audit.log("PRICE_EDIT", "Product", p.getId(), p.getName() + " " + basePrice + " -> " + lr.unitPrice());
        } else l.setUnitPrice(basePrice);
        checkDiscount(lr.discountPercent(), lr.discountAmount(), p.getName());
        l.setDiscountPercent(Money.nz(lr.discountPercent()));
        l.setDiscountAmount(Money.nz(lr.discountAmount()));
        // modifiers
        Map<Long, ModifierGroup> allowed = new HashMap<>();
        for (ProductModifierGroup pmg : p.getModifierGroups()) if (pmg.getModifierGroup().isActive()) allowed.put(pmg.getModifierGroup().getId(), pmg.getModifierGroup());
        // Le client envoie une occurrence par ajout : « fromage » trois fois arrive
        // trois fois. On regroupe en une ligne portant sa quantité, plutôt que trois
        // lignes identiques sur le ticket de cuisine.
        Map<Long, Integer> perGroup = new HashMap<>();
        Map<Long, Integer> perModifier = new LinkedHashMap<>();
        if (lr.modifierIds() != null) for (Long mid : lr.modifierIds()) perModifier.merge(mid, 1, Integer::sum);
        for (Map.Entry<Long, Integer> e : perModifier.entrySet()) {
            Modifier m = modifierRepo.findById(e.getKey()).orElseThrow(() -> BusinessException.notFound("Option #" + e.getKey()));
            if (!m.isActive() || !allowed.containsKey(m.getGroup().getId())) throw new BusinessException("L'option « " + m.getName() + " » n'est pas valide pour « " + p.getName() + " ».");
            ModifierGroup g = allowed.get(m.getGroup().getId());
            // Répéter une même option n'a de sens que dans un groupe sans maximum :
            // ailleurs, cela contournerait silencieusement la limite configurée.
            boolean repetable = g.isMultiple() && g.getMaxSelect() <= 0;
            if (e.getValue() > 1 && !repetable)
                throw new BusinessException("« " + g.getName() + " » : l'option « " + m.getName() + " » ne peut être ajoutée qu'une fois.");
            perGroup.merge(g.getId(), e.getValue(), Integer::sum);
            OrderLineModifier om = new OrderLineModifier();
            om.setOrderLine(l); om.setModifier(m); om.setModifierName(m.getName());
            om.setPriceDelta(Money.nz(m.getPriceDelta())); om.setQuantity(e.getValue());
            l.getModifiers().add(om);
        }
        for (ModifierGroup g : allowed.values()) {
            int n = perGroup.getOrDefault(g.getId(), 0);
            if (g.isRequired() && n < Math.max(1, g.getMinSelect())) throw new BusinessException("« " + p.getName() + " » : le choix « " + g.getName() + " » est obligatoire.");
            if (n < g.getMinSelect() && n > 0) throw new BusinessException("« " + g.getName() + " » : minimum " + g.getMinSelect() + " option(s).");
            int max = g.isMultiple() ? g.getMaxSelect() : 1;
            if (max > 0 && n > max) throw new BusinessException("« " + g.getName() + " » : maximum " + max + " option(s).");
        }
        // menu components
        if (p.getProductType() == Enums.ProductType.MENU && parent == null) {
            List<CartLineRequest> comps = lr.components() == null ? List.of() : lr.components();
            int j = 0;
            for (MenuComponent mc : p.getMenuComponents()) {
                Set<Long> optionIds = mc.getOptions().stream().map(x -> x.getProduct().getId()).collect(Collectors.toSet());
                BigDecimal chosen = comps.stream().filter(c -> optionIds.contains(c.productId())).map(c -> Money.nz(c.quantity())).reduce(BigDecimal.ZERO, BigDecimal::add);
                if (chosen.compareTo(BigDecimal.valueOf(mc.getQuantity())) != 0)
                    throw new BusinessException("Menu « " + p.getName() + " » : choisissez " + mc.getQuantity() + " « " + mc.getName() + " ».");
            }
            for (CartLineRequest c : comps) {
                boolean known = p.getMenuComponents().stream().anyMatch(mc -> mc.getOptions().stream().anyMatch(x -> x.getProduct().getId().equals(c.productId())));
                if (!known) throw new BusinessException("Composant de menu invalide.");
                l.getComponents().add(buildLine(o, new CartLineRequest(c.productId(), c.quantity(), null, null, null, c.note(), c.modifierIds(), null), l, j++));
            }
        } else if (lr.components() != null && !lr.components().isEmpty()) throw new BusinessException("« " + p.getName() + " » n'est pas un menu.");
        return l;
    }

    private static BigDecimal componentDelta(Product menu, Product component) {
        if (menu == null) return BigDecimal.ZERO;
        for (MenuComponent mc : menu.getMenuComponents())
            for (MenuComponentProduct op : mc.getOptions())
                if (op.getProduct().getId().equals(component.getId())) return Money.nz(op.getPriceDelta());
        return BigDecimal.ZERO;
    }

    private void checkDiscount(BigDecimal percent, BigDecimal amount, String what) {
        boolean any = Money.isPositive(percent) || Money.isPositive(amount);
        if (!any) return;
        if (Money.nz(percent).signum() < 0 || Money.nz(amount).signum() < 0) throw new BusinessException("Remise invalide.");
        if (Money.nz(percent).compareTo(Money.HUNDRED) > 0) throw new BusinessException("La remise ne peut pas dépasser 100 %.");
        if (!currentUser.has(Permission.DISCOUNT_APPLY)) throw BusinessException.forbidden("Vous n'avez pas la permission d'appliquer une remise.");
        BigDecimal threshold = settings.getDecimal(SettingsService.DISCOUNT_HIGH_THRESHOLD, BigDecimal.TEN);
        User me = currentUser.entity();
        if (me.getMaxDiscountPercent() != null && Money.nz(percent).compareTo(me.getMaxDiscountPercent()) > 0)
            throw BusinessException.forbidden("Votre remise maximale autorisée est de " + me.getMaxDiscountPercent().stripTrailingZeros().toPlainString() + " %.");
        if (Money.nz(percent).compareTo(threshold) > 0 && !currentUser.has(Permission.DISCOUNT_HIGH))
            throw BusinessException.forbidden("Une remise supérieure à " + threshold.stripTrailingZeros().toPlainString() + " % nécessite l'autorisation d'un manager.");
    }

    private void applyPayments(SaleOrder o, List<PaymentRequest> payments, RegisterSession session) {
        BigDecimal total = o.getTotal();
        BigDecimal sum = BigDecimal.ZERO;
        BigDecimal change = BigDecimal.ZERO;
        Payment cashPayment = null;
        for (PaymentRequest pr : payments) {
            PaymentMethod m = paymentMethodRepo.findById(pr.paymentMethodId()).orElseThrow(() -> BusinessException.notFound("Moyen de paiement"));
            if (!m.isActive()) throw new BusinessException("Le moyen de paiement « " + m.getName() + " » est désactivé.");
            if (pr.amount() == null || pr.amount().signum() <= 0) throw new BusinessException("Montant de paiement invalide.");
            Payment p = new Payment();
            p.setOrder(o); p.setSession(session); p.setPaymentMethod(m); p.setAmount(Money.r(pr.amount())); p.setReference(pr.reference());
            if (m.getKind() == Enums.PaymentKind.CASH) {
                p.setTendered(pr.tendered() == null ? p.getAmount() : Money.r(pr.tendered()));
                if (p.getTendered().compareTo(p.getAmount()) < 0) throw new BusinessException("Le montant reçu en espèces est inférieur au montant appliqué.");
                cashPayment = p;
            }
            sum = sum.add(p.getAmount());
            o.getPayments().add(p);
        }
        BigDecimal diff = sum.subtract(total);
        if (diff.abs().compareTo(TOLERANCE) > 0) {
            if (diff.signum() > 0 && cashPayment != null) {
                // over-payment in cash: reduce the cash amount applied and give change
                BigDecimal applied = cashPayment.getAmount().subtract(diff);
                if (applied.signum() < 0) throw new BusinessException("Le total des paiements dépasse le montant à payer.");
                cashPayment.setAmount(Money.r(applied));
                if (cashPayment.getTendered().compareTo(cashPayment.getAmount()) < 0) cashPayment.setTendered(cashPayment.getAmount());
            } else if (diff.signum() < 0) {
                throw new BusinessException("Paiement insuffisant : il manque " + Money.r(diff.abs()) + ".");
            } else throw new BusinessException("Le total des paiements dépasse le montant à payer.");
        }
        if (cashPayment != null) {
            change = PricingService.change(cashPayment.getAmount(), cashPayment.getTendered());
            cashPayment.setChangeGiven(change);
        }
        o.setPaidTotal(Money.r(o.getPayments().stream().map(Payment::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add)));
        o.setChangeAmount(change);
    }

    // =================== HOLD / RESUME ===================
    @Transactional
    public OrderDto hold(CartRequest req) {
        currentUser.require(Permission.SELL, "Vous n'avez pas la permission de vendre.");
        User me = currentUser.entity();
        Register reg = registerRepo.findById(req.registerId()).orElseThrow(() -> BusinessException.notFound("Caisse"));
        RegisterSession session = sessions.requireOpenSession(reg.getId());
        SaleOrder o;
        if (req.heldOrderId() != null) {
            o = orderRepo.findById(req.heldOrderId()).filter(h -> h.getStatus() == Enums.OrderStatus.HELD).orElseGet(SaleOrder::new);
        } else o = new SaleOrder();
        fillOrder(o, reg, session, me, req.serviceMode(), req.customerId(), req.customerName(), req.customerPhone(), req.note(), req.discountPercent(), req.discountAmount(), req.lines());
        pricing.computeOrder(o);
        o.setStatus(Enums.OrderStatus.HELD);
        o.setUpdatedAt(OffsetDateTime.now());
        if (o.getHeldRef() == null) {
            DocumentSequence seq = sequenceRepo.lockByKey("HOLD").orElseGet(() -> { DocumentSequence s = new DocumentSequence(); s.setScopeKey("HOLD"); return sequenceRepo.saveAndFlush(s); });
            long v = seq.getNextValue(); seq.setNextValue(v + 1); sequenceRepo.save(seq);
            o.setHeldRef("A-" + v);
        }
        SaleOrder saved = orderRepo.saveAndFlush(o);
        audit.log("ORDER_HOLD", "Order", saved.getId(), saved.getHeldRef() + " total=" + saved.getTotal());
        return toDto(saved);
    }

    @Transactional(readOnly = true)
    public List<OrderDto> heldOrders(Long posId) {
        List<SaleOrder> list = posId == null ? orderRepo.findByStatusOrderByCreatedAtAsc(Enums.OrderStatus.HELD)
                : orderRepo.findByStatusAndRegisterPointOfSaleIdOrderByCreatedAtAsc(Enums.OrderStatus.HELD, posId);
        return list.stream().map(this::toDto).toList();
    }

    @Transactional
    public void abandonHeld(Long id) {
        SaleOrder o = orderRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Commande"));
        if (o.getStatus() != Enums.OrderStatus.HELD) throw BusinessException.conflict("Seule une commande en attente peut être abandonnée.");
        currentUser.require(Permission.ORDER_CANCEL, "Vous n'avez pas la permission d'abandonner une commande.");
        audit.log("ORDER_ABANDON", "Order", id, o.getHeldRef() + " total=" + o.getTotal());
        orderRepo.delete(o);
    }

    // =================== CANCEL / REFUND ===================
    @Transactional
    public OrderDto cancel(Long id, CancelRequest req) {
        currentUser.require(Permission.TICKET_CANCEL, "L'annulation d'un ticket encaissé nécessite l'autorisation d'un manager.");
        SaleOrder o = orderRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Ticket"));
        if (o.getStatus() == Enums.OrderStatus.CANCELLED) throw BusinessException.conflict("Ce ticket est déjà annulé.");
        if (o.getStatus() == Enums.OrderStatus.HELD) throw BusinessException.conflict("Cette commande n'est pas encaissée : abandonnez-la depuis les commandes en attente.");
        User me = currentUser.entity();
        BigDecimal remaining = o.getTotal().subtract(Money.nz(o.getRefundedTotal()));
        RegisterSession session = refundSession(o, me);
        if (remaining.signum() > 0) {
            PaymentMethod m = req.refundMethodId() != null ? paymentMethodRepo.findById(req.refundMethodId()).orElseThrow(() -> BusinessException.notFound("Moyen de paiement"))
                    : o.getPayments().isEmpty() ? paymentMethodRepo.findFirstByKindAndActiveTrue(Enums.PaymentKind.CASH).orElseThrow() : o.getPayments().get(0).getPaymentMethod();
            Refund r = new Refund();
            r.setOrder(o); r.setSession(session); r.setUser(me); r.setPaymentMethod(m); r.setAmount(Money.r(remaining)); r.setReason(req.reason().trim()); r.setKind("CANCELLATION");
            refundRepo.save(r);
            journal.record(session, me, Enums.JournalEvent.REFUND, r.getAmount(), o.getTicketNumber(), "Remboursement (annulation) " + m.getName());
        }
        o.setRefundedTotal(o.getTotal());
        o.setStatus(Enums.OrderStatus.CANCELLED);
        o.setCancelReason(req.reason().trim()); o.setCancelledBy(me); o.setCancelledAt(OffsetDateTime.now()); o.setUpdatedAt(OffsetDateTime.now());
        SaleOrder saved = orderRepo.saveAndFlush(o);
        journal.record(session, me, Enums.JournalEvent.CANCELLATION, saved.getTotal(), saved.getTicketNumber(), "Annulation ticket : " + req.reason());
        audit.log("TICKET_CANCEL", "Order", saved.getId(), saved.getTicketNumber() + " motif=" + req.reason() + " montant=" + saved.getTotal());
        return toDto(saved);
    }

    @Transactional
    public OrderDto refund(Long id, RefundRequest req) {
        currentUser.require(Permission.REFUND, "Vous n'avez pas la permission de rembourser.");
        SaleOrder o = orderRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Ticket"));
        if (o.getStatus() == Enums.OrderStatus.CANCELLED || o.getStatus() == Enums.OrderStatus.HELD) throw BusinessException.conflict("Ce ticket ne peut pas être remboursé.");
        if (req.amount().signum() <= 0) throw new BusinessException("Le montant du remboursement doit être supérieur à zéro.");
        BigDecimal remaining = o.getTotal().subtract(Money.nz(o.getRefundedTotal()));
        if (Money.r(req.amount()).compareTo(remaining) > 0) throw new BusinessException("Le remboursement dépasse le montant restant (" + remaining + ").");
        User me = currentUser.entity();
        RegisterSession session = refundSession(o, me);
        PaymentMethod m = paymentMethodRepo.findById(req.paymentMethodId()).orElseThrow(() -> BusinessException.notFound("Moyen de paiement"));
        Refund r = new Refund();
        r.setOrder(o); r.setSession(session); r.setUser(me); r.setPaymentMethod(m); r.setAmount(Money.r(req.amount())); r.setReason(req.reason().trim());
        refundRepo.save(r);
        o.setRefundedTotal(Money.r(Money.nz(o.getRefundedTotal()).add(r.getAmount())));
        o.setStatus(o.getRefundedTotal().compareTo(o.getTotal()) >= 0 ? Enums.OrderStatus.REFUNDED : Enums.OrderStatus.PARTIALLY_REFUNDED);
        o.setUpdatedAt(OffsetDateTime.now());
        SaleOrder saved = orderRepo.saveAndFlush(o);
        journal.record(session, me, Enums.JournalEvent.REFUND, r.getAmount(), saved.getTicketNumber(), "Remboursement " + m.getName() + " : " + req.reason());
        audit.log("REFUND", "Order", saved.getId(), saved.getTicketNumber() + " montant=" + r.getAmount() + " motif=" + req.reason());
        return toDto(saved);
    }

    /** Refunds are booked on the current user's open session when there is one (money leaves that drawer), else on the sale's session. */
    private RegisterSession refundSession(SaleOrder o, User me) {
        return sessionRepo.findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(me.getId(), Enums.SessionStatus.OPEN)
                .or(() -> o.getSession() != null && o.getSession().getStatus() == Enums.SessionStatus.OPEN ? Optional.of(o.getSession()) : Optional.empty())
                .orElseThrow(() -> BusinessException.conflict("Aucune caisse ouverte : ouvrez une session de caisse pour enregistrer le remboursement."));
    }

    // =================== READ / SEARCH ===================
    @Transactional(readOnly = true)
    public OrderDto get(Long id) { return toDto(orderRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Ticket"))); }

    @Transactional(readOnly = true)
    public OrderDto byTicket(String ticket) { return toDto(orderRepo.findByTicketNumber(ticket).orElseThrow(() -> BusinessException.notFound("Ticket"))); }

    @Transactional
    public List<PrintJobDto> reprint(Long id) {
        currentUser.require(Permission.TICKETS_REPRINT, "Vous n'avez pas la permission de réimprimer.");
        SaleOrder o = orderRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Ticket"));
        if (o.getStatus() == Enums.OrderStatus.HELD) throw new BusinessException("Une commande en attente n'a pas de ticket.");
        List<PrintJob> jobs = printService.createJobs(o, true);
        audit.log("TICKET_REPRINT", "Order", id, o.getTicketNumber());
        return jobs.stream().map(Mappers::printJob).toList();
    }

    @Transactional(readOnly = true)
    public PageDto<OrderSummaryDto> search(OffsetDateTime from, OffsetDateTime to, String status, Long registerId, Long cashierId, Long posId,
                                           String ticket, BigDecimal minAmount, BigDecimal maxAmount, String methodCode, Long sessionId, int page, int size) {
        Specification<SaleOrder> spec = (root, q, cb) -> {
            List<Predicate> p = new ArrayList<>();
            p.add(cb.notEqual(root.get("status"), Enums.OrderStatus.HELD));
            if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            if (to != null) p.add(cb.lessThan(root.get("createdAt"), to));
            if (status != null && !status.isBlank()) p.add(cb.equal(root.get("status"), Enums.OrderStatus.valueOf(status)));
            if (registerId != null) p.add(cb.equal(root.get("register").get("id"), registerId));
            if (cashierId != null) p.add(cb.equal(root.get("cashier").get("id"), cashierId));
            if (posId != null) p.add(cb.equal(root.get("pointOfSale").get("id"), posId));
            if (sessionId != null) p.add(cb.equal(root.get("session").get("id"), sessionId));
            if (ticket != null && !ticket.isBlank()) p.add(cb.like(cb.lower(root.get("ticketNumber")), "%" + ticket.toLowerCase().trim() + "%"));
            if (minAmount != null) p.add(cb.greaterThanOrEqualTo(root.get("total"), minAmount));
            if (maxAmount != null) p.add(cb.lessThanOrEqualTo(root.get("total"), maxAmount));
            if (methodCode != null && !methodCode.isBlank()) {
                Join<SaleOrder, Payment> pay = root.join("payments");
                p.add(cb.equal(pay.get("paymentMethod").get("code"), methodCode));
                q.distinct(true);
            }
            return cb.and(p.toArray(new Predicate[0]));
        };
        Page<SaleOrder> res = orderRepo.findAll(spec, PageRequest.of(Math.max(0, page), Math.min(Math.max(size, 1), 500), Sort.by(Sort.Direction.DESC, "createdAt")));
        return new PageDto<>(res.getContent().stream().map(Mappers::orderSummary).toList(), res.getTotalElements(), page, size);
    }

    /** Receipt template live preview (rendered inside one transaction so lazy associations are available). */
    @Transactional(readOnly = true)
    public java.util.Map<String, Object> receiptPreview(com.poscaisse.dto.AdminDtos.ReceiptTemplateRequest r) {
        return printService.preview(r, sampleOrder());
    }

    /** Latest real sale, or a synthetic one, for the receipt template preview. */
    @Transactional(readOnly = true)
    public SaleOrder sampleOrder() {
        Page<SaleOrder> last = orderRepo.findAll((root, q, cb) -> cb.equal(root.get("status"), Enums.OrderStatus.PAID), PageRequest.of(0, 1, Sort.by(Sort.Direction.DESC, "id")));
        if (!last.isEmpty()) { SaleOrder o = last.getContent().get(0); o.getLines().size(); o.getPayments().size(); return o; }
        Register reg = registerRepo.findAllByOrderByCodeAsc().stream().findFirst().orElseThrow(() -> BusinessException.notFound("Caisse"));
        SaleOrder o = new SaleOrder();
        o.setRegister(reg); o.setPointOfSale(reg.getPointOfSale()); o.setCashier(currentUser.entity()); o.setTicketNumber("PV01-2026-000001");
        o.setStatus(Enums.OrderStatus.PAID); o.setPaidAt(OffsetDateTime.now()); o.setServiceMode(Enums.ServiceMode.TAKEAWAY);
        List<Product> prods = productRepo.findByActiveTrueOrderBySortOrderAscNameAsc();
        int i = 0;
        for (Product p : prods.stream().limit(3).toList()) {
            OrderLine l = new OrderLine(); l.setOrder(o); l.setProduct(p); l.setProductName(p.getName()); l.setProductCode(p.getCode());
            l.setQuantity(BigDecimal.valueOf(i == 0 ? 2 : 1)); l.setUnitPrice(p.getPrice()); l.setOriginalUnitPrice(p.getPrice()); l.setTaxRate(p.getTaxRate()); l.setSortOrder(i++);
            o.getLines().add(l);
        }
        pricing.computeOrder(o);
        PaymentMethod cash = paymentMethodRepo.findFirstByKindAndActiveTrue(Enums.PaymentKind.CASH).orElse(null);
        if (cash != null) { Payment p = new Payment(); p.setOrder(o); p.setPaymentMethod(cash); p.setAmount(o.getTotal()); p.setTendered(o.getTotal().add(BigDecimal.TEN)); p.setChangeGiven(BigDecimal.TEN); o.getPayments().add(p); o.setChangeAmount(BigDecimal.TEN); o.setPaidTotal(o.getTotal()); }
        return o;
    }

    private OrderDto toDto(SaleOrder o) {
        return Mappers.order(o, refundRepo.findByOrderIdOrderByCreatedAtAsc(o.getId()), o.getId() == null ? List.of() : printJobRepo.findByOrderIdOrderByIdAsc(o.getId()));
    }
}
