package com.poscaisse.service;

import com.poscaisse.domain.*;
import com.poscaisse.dto.AdminDtos.*;
import com.poscaisse.dto.AuthDtos.*;
import com.poscaisse.dto.CatalogDtos.*;
import com.poscaisse.dto.OrderDtos.*;
import com.poscaisse.dto.RegisterDtos.*;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

public final class Mappers {
    private Mappers() {}

    public static CategoryDto category(Category c, long count) {
        return new CategoryDto(c.getId(), c.getName(), c.getColor(), c.getIcon(), c.getSortOrder(), c.isActive(),
                c.getPrintDestination() == null ? null : c.getPrintDestination().getId(), count);
    }

    public static ModifierDto modifier(Modifier m) {
        return new ModifierDto(m.getId(), m.getName(), m.getPriceDelta(), m.getSortOrder(), m.isActive());
    }

    public static ModifierGroupDto modifierGroup(ModifierGroup g) {
        return new ModifierGroupDto(g.getId(), g.getName(), g.isRequired(), g.isMultiple(), g.getMinSelect(), g.getMaxSelect(),
                g.getSortOrder(), g.isActive(), g.getModifiers().stream().filter(Modifier::isActive)
                .sorted(Comparator.comparingInt(Modifier::getSortOrder).thenComparing(Modifier::getId)).map(Mappers::modifier).toList());
    }

    public static MenuComponentDto menuComponent(MenuComponent c) {
        return new MenuComponentDto(c.getId(), c.getName(), c.getQuantity(), c.getSortOrder(),
                c.getOptions().stream().map(o -> new MenuOptionDto(o.getProduct().getId(), o.getProduct().getName(), o.getPriceDelta(),
                        o.getProduct().isActive() && o.getProduct().isAvailable())).toList());
    }

    public static ProductDto product(Product p) {
        return new ProductDto(p.getId(), p.getCode(), p.getReference(), p.getName(), p.getShortName(), p.getDescription(),
                p.getCategory().getId(), p.getCategory().getName(), p.getProductType().name(), p.getPrice(), p.getTaxRate(),
                p.getImageUrl(), p.getColor(), p.getSortOrder(), p.isActive(), p.isAvailable(), p.isFavorite(), p.getFavoriteOrder(),
                p.getPrintDestinations().stream().map(PrintDestination::getId).sorted().toList(),
                p.getModifierGroups().stream().sorted(Comparator.comparingInt(ProductModifierGroup::getSortOrder))
                        .map(ProductModifierGroup::getModifierGroup).filter(ModifierGroup::isActive).map(Mappers::modifierGroup).toList(),
                p.getMenuComponents().stream().sorted(Comparator.comparingInt(MenuComponent::getSortOrder)).map(Mappers::menuComponent).toList());
    }

    public static PaymentMethodDto paymentMethod(PaymentMethod m) {
        return new PaymentMethodDto(m.getId(), m.getCode(), m.getName(), m.getKind().name(), m.isOpensDrawer(), m.getSortOrder(), m.isActive());
    }

    public static UserTile userTile(User u) {
        return new UserTile(u.getId(), u.getFullName(), u.getUsername(), u.getColor(), u.getRole().getCode(), u.getRole().getName());
    }

    public static CurrentUserDto currentUser(User u) {
        return new CurrentUserDto(u.getId(), u.getUsername(), u.getFullName(), u.getRole().getCode(), u.getRole().getName(),
                u.getRole().getPermissions().stream().map(Enum::name).collect(Collectors.toSet()),
                u.getPointOfSale() == null ? null : u.getPointOfSale().getId(), u.getMaxDiscountPercent());
    }

    public static UserDto user(User u) {
        return new UserDto(u.getId(), u.getUsername(), u.getFullName(), u.getRole().getId(), u.getRole().getCode(), u.getRole().getName(),
                u.getPointOfSale() == null ? null : u.getPointOfSale().getId(), u.getMaxDiscountPercent(), u.getColor(), u.isActive(),
                u.getPinHash() != null, u.getPasswordHash() != null, u.getLastLoginAt());
    }

    public static RoleDto role(Role r, long userCount) {
        return new RoleDto(r.getId(), r.getCode(), r.getName(), r.isSystemRole(), r.getPermissions().stream().map(Enum::name).sorted().toList(), userCount);
    }

    public static CompanyDto company(Company c) {
        return new CompanyDto(c.getId(), c.getName(), c.getTradeName(), c.getAddress(), c.getPhone(), c.getTaxId(), c.getCurrency(),
                c.getCurrencySymbol(), c.getDecimals(), c.getTimezone(), c.getLogoData());
    }

    public static PointOfSaleDto pos(PointOfSale p, int registers) {
        return new PointOfSaleDto(p.getId(), p.getCode(), p.getName(), p.getAddress(), p.getPhone(), p.isActive(), registers);
    }

    public static RegisterDto register(Register r) {
        return new RegisterDto(r.getId(), r.getCode(), r.getName(), r.getPointOfSale().getId(), r.getPointOfSale().getName(), r.isActive());
    }

    public static PrintDestinationDto destination(PrintDestination d) {
        return new PrintDestinationDto(d.getId(), d.getCode(), d.getName(), d.getKind().name(), d.getCopies(), d.isShowPrices(), d.getSortOrder(), d.isActive());
    }

    public static SessionInfo sessionInfo(RegisterSession s) {
        if (s == null) return null;
        Register r = s.getRegister();
        return new SessionInfo(s.getId(), r.getId(), r.getCode(), r.getName(), r.getPointOfSale().getId(), r.getPointOfSale().getName(),
                s.getOpenedAt(), s.getOpeningFloat(), s.getOpenedBy().getId(), s.getOpenedBy().getFullName());
    }

    public static SessionDto session(RegisterSession s) {
        if (s == null) return null;
        Register r = s.getRegister();
        return new SessionDto(s.getId(), r.getId(), r.getCode(), r.getName(), r.getPointOfSale().getId(), r.getPointOfSale().getName(),
                s.getStatus().name(), s.getOpenedAt(), s.getClosedAt(), s.getOpenedBy().getId(), s.getOpenedBy().getFullName(),
                s.getClosedBy() == null ? null : s.getClosedBy().getId(), s.getClosedBy() == null ? null : s.getClosedBy().getFullName(),
                s.getOpeningFloat(), s.getCashSales(), s.getCardSales(), s.getOtherSales(), s.getCashRefunds(), s.getCashIn(), s.getCashOut(),
                s.getExpectedCash(), s.getCountedCash(), s.getCashDifference(), s.getTicketsCount(), s.getRevenue(), s.getClosingNote());
    }

    public static CashMovementDto movement(CashMovement m) {
        return new CashMovementDto(m.getId(), m.getSession().getId(), m.getMovementType().name(), m.getReason(), m.getAmount(), m.getComment(),
                m.getUser().getFullName(), m.getCreatedAt());
    }

    public static JournalDto journal(RegisterJournal j) {
        return new JournalDto(j.getId(), j.getPointOfSale() == null ? null : j.getPointOfSale().getId(),
                j.getPointOfSale() == null ? null : j.getPointOfSale().getName(),
                j.getRegister() == null ? null : j.getRegister().getId(), j.getRegister() == null ? null : j.getRegister().getCode(),
                j.getSession() == null ? null : j.getSession().getId(), j.getUser() == null ? null : j.getUser().getId(),
                j.getUser() == null ? null : j.getUser().getFullName(), j.getEventType().name(), j.getAmount(), j.getReference(),
                j.getDescription(), j.getCreatedAt());
    }

    public static OrderLineDto line(OrderLine l) {
        return new OrderLineDto(l.getId(), l.getProduct() == null ? null : l.getProduct().getId(), l.getProductCode(), l.getProductName(),
                l.getCategory() == null ? null : l.getCategory().getId(), l.getQuantity(), l.getOriginalUnitPrice(), l.getUnitPrice(),
                l.getModifiersTotal(), l.getDiscountPercent(), l.getDiscountAmount(), l.getTaxRate(), l.getLineTotal(), l.getNote(),
                l.getModifiers().stream().map(m -> new LineModifierDto(m.getModifier() == null ? null : m.getModifier().getId(), m.getModifierName(), m.getPriceDelta(), m.getQuantity())).toList(),
                l.getComponents().stream().map(Mappers::line).toList());
    }

    public static PaymentDto payment(Payment p) {
        return new PaymentDto(p.getId(), p.getPaymentMethod().getId(), p.getPaymentMethod().getCode(), p.getPaymentMethod().getName(),
                p.getAmount(), p.getTendered(), p.getChangeGiven(), p.getReference(), p.getCreatedAt());
    }

    public static RefundDto refund(Refund r) {
        return new RefundDto(r.getId(), r.getOrder().getId(), r.getOrder().getTicketNumber(), r.getAmount(), r.getReason(),
                r.getPaymentMethod().getName(), r.getUser().getFullName(), r.getCreatedAt(), r.getKind());
    }

    public static PrintJobDto printJob(PrintJob j) {
        return new PrintJobDto(j.getId(), j.getOrder() == null ? null : j.getOrder().getId(), j.getDestination() == null ? null : j.getDestination().getId(),
                j.getDestinationCode(), j.getTitle(), j.getCopies(), j.getContent(), j.getStatus().name(), j.isDuplicate(), j.getCreatedAt());
    }

    public static OrderDto order(SaleOrder o, List<Refund> refunds, List<PrintJob> jobs) {
        return new OrderDto(o.getId(), o.getClientRef(), o.getTicketNumber(), o.getHeldRef(), o.getStatus().name(), o.getServiceMode().name(),
                o.getPointOfSale().getId(), o.getPointOfSale().getName(), o.getRegister().getId(), o.getRegister().getCode(),
                o.getSession() == null ? null : o.getSession().getId(), o.getCashier().getId(), o.getCashier().getFullName(),
                o.getCustomer() == null ? null : o.getCustomer().getId(), o.getCustomerName(), o.getCustomerPhone(), o.getNote(),
                o.getSubtotal(), o.getLineDiscountTotal(), o.getDiscountPercent(), o.getDiscountAmount(), o.getTaxTotal(), o.getTotal(),
                o.getPaidTotal(), o.getChangeAmount(), o.getRefundedTotal(), o.getCancelReason(), o.getCreatedAt(), o.getPaidAt(), o.getCancelledAt(),
                o.getLines().stream().filter(l -> l.getParentLine() == null).map(Mappers::line).toList(),
                o.getPayments().stream().map(Mappers::payment).toList(),
                refunds == null ? List.of() : refunds.stream().map(Mappers::refund).toList(),
                jobs == null ? List.of() : jobs.stream().map(Mappers::printJob).toList());
    }

    public static OrderSummaryDto orderSummary(SaleOrder o) {
        String pay = o.getPayments().stream().map(p -> p.getPaymentMethod().getName()).distinct().collect(Collectors.joining(" + "));
        int items = o.getLines().stream().filter(l -> l.getParentLine() == null).mapToInt(l -> l.getQuantity().intValue()).sum();
        return new OrderSummaryDto(o.getId(), o.getTicketNumber(), o.getHeldRef(), o.getStatus().name(), o.getServiceMode().name(),
                o.getRegister().getCode(), o.getCashier().getFullName(), o.getCustomerName(), o.getTotal(), o.getRefundedTotal(), pay,
                o.getCreatedAt(), o.getPaidAt(), items);
    }

    public static AuditDto audit(AuditLog a) {
        return new AuditDto(a.getId(), a.getUserId(), a.getUsername(), a.getAction(), a.getEntityType(), a.getEntityId(), a.getDetails(), a.getCreatedAt());
    }

    public static CustomerDto customer(Customer c) {
        return new CustomerDto(c.getId(), c.getName(), c.getPhone(), c.getNote(), c.getCreatedAt());
    }
}
