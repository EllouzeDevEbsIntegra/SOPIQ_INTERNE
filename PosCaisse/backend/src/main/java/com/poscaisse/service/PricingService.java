package com.poscaisse.service;

import com.poscaisse.domain.OrderLine;
import com.poscaisse.domain.OrderLineModifier;
import com.poscaisse.domain.SaleOrder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/** Pure pricing rules (no persistence) — shared by checkout, hold and quote, and unit-tested. */
@Service
public class PricingService {

    /** Computes modifiersTotal, discountAmount and lineTotal of a line (including menu components). */
    public void computeLine(OrderLine line) {
        BigDecimal mods = line.getModifiers().stream().map(OrderLineModifier::getPriceDelta).map(Money::nz)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal componentsUnit = BigDecimal.ZERO;
        for (OrderLine c : line.getComponents()) {
            computeLine(c);
            // component line totals are expressed per menu unit (component qty * component unit incl. its modifiers)
            componentsUnit = componentsUnit.add(c.getLineTotal());
        }
        line.setModifiersTotal(Money.r(mods));
        BigDecimal unit = Money.nz(line.getUnitPrice()).add(mods).add(componentsUnit);
        BigDecimal gross = Money.r(unit.multiply(Money.nz(line.getQuantity())));
        BigDecimal discount;
        if (Money.isPositive(line.getDiscountAmount())) {
            discount = Money.r(line.getDiscountAmount().min(gross));
            line.setDiscountPercent(gross.signum() == 0 ? BigDecimal.ZERO : discount.multiply(Money.HUNDRED).divide(gross, 2, RoundingMode.HALF_UP));
        } else {
            discount = Money.pct(gross, line.getDiscountPercent());
            line.setDiscountPercent(Money.nz(line.getDiscountPercent()).setScale(2, RoundingMode.HALF_UP));
        }
        line.setDiscountAmount(discount);
        line.setLineTotal(Money.r(gross.subtract(discount)));
    }

    /** Computes subtotal, discounts, tax and total of an order from its (already computed) lines. */
    public void computeOrder(SaleOrder order) {
        List<OrderLine> lines = order.getLines();
        BigDecimal subtotal = BigDecimal.ZERO, lineDiscounts = BigDecimal.ZERO, afterLine = BigDecimal.ZERO;
        for (OrderLine l : lines) {
            if (l.getParentLine() != null) continue;
            computeLine(l);
            subtotal = subtotal.add(l.getLineTotal()).add(l.getDiscountAmount());
            lineDiscounts = lineDiscounts.add(l.getDiscountAmount());
            afterLine = afterLine.add(l.getLineTotal());
        }
        BigDecimal orderDiscount;
        if (Money.isPositive(order.getDiscountAmount())) {
            orderDiscount = Money.r(order.getDiscountAmount().min(afterLine));
            order.setDiscountPercent(afterLine.signum() == 0 ? BigDecimal.ZERO : orderDiscount.multiply(Money.HUNDRED).divide(afterLine, 2, RoundingMode.HALF_UP));
        } else {
            orderDiscount = Money.pct(afterLine, order.getDiscountPercent());
            order.setDiscountPercent(Money.nz(order.getDiscountPercent()).setScale(2, RoundingMode.HALF_UP));
        }
        BigDecimal total = Money.r(afterLine.subtract(orderDiscount));
        // tax (prices are tax-inclusive): pro-rata of the order discount on each line
        BigDecimal ratio = afterLine.signum() == 0 ? BigDecimal.ONE : total.divide(afterLine, 8, RoundingMode.HALF_UP);
        BigDecimal tax = BigDecimal.ZERO;
        for (OrderLine l : lines) {
            if (l.getParentLine() != null) continue;
            tax = tax.add(Money.taxIncluded(l.getLineTotal().multiply(ratio), l.getTaxRate()));
        }
        order.setSubtotal(Money.r(subtotal));
        order.setLineDiscountTotal(Money.r(lineDiscounts));
        order.setDiscountAmount(orderDiscount);
        order.setTaxTotal(Money.r(tax));
        order.setTotal(total);
    }

    /** Change to give back for a cash payment. */
    public static BigDecimal change(BigDecimal due, BigDecimal tendered) {
        if (tendered == null) return BigDecimal.ZERO.setScale(Money.SCALE);
        BigDecimal c = tendered.subtract(due);
        return c.signum() > 0 ? Money.r(c) : BigDecimal.ZERO.setScale(Money.SCALE);
    }
}
