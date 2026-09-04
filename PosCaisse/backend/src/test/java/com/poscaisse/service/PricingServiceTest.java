package com.poscaisse.service;

import com.poscaisse.domain.OrderLine;
import com.poscaisse.domain.OrderLineModifier;
import com.poscaisse.domain.SaleOrder;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class PricingServiceTest {
    private final PricingService pricing = new PricingService();

    private static OrderLine line(String price, String qty, String... modDeltas) {
        OrderLine l = new OrderLine();
        l.setUnitPrice(new BigDecimal(price)); l.setOriginalUnitPrice(l.getUnitPrice()); l.setQuantity(new BigDecimal(qty));
        for (String d : modDeltas) { OrderLineModifier m = new OrderLineModifier(); m.setModifierName("m"); m.setPriceDelta(new BigDecimal(d)); l.getModifiers().add(m); }
        return l;
    }

    @Test void lineTotalWithQuantityAndModifiers() {
        OrderLine l = line("7.500", "2", "1.000");
        pricing.computeLine(l);
        assertThat(l.getModifiersTotal()).isEqualByComparingTo("1.000");
        assertThat(l.getLineTotal()).isEqualByComparingTo("17.000");
    }

    @Test void lineDiscountPercentIsRoundedTo3Decimals() {
        OrderLine l = line("8.500", "3");
        l.setDiscountPercent(new BigDecimal("10"));
        pricing.computeLine(l);
        assertThat(l.getDiscountAmount()).isEqualByComparingTo("2.550");
        assertThat(l.getLineTotal()).isEqualByComparingTo("22.950");
    }

    @Test void lineDiscountAmountCannotExceedGross() {
        OrderLine l = line("2.000", "1");
        l.setDiscountAmount(new BigDecimal("5"));
        pricing.computeLine(l);
        assertThat(l.getLineTotal()).isEqualByComparingTo("0.000");
        assertThat(l.getDiscountPercent()).isEqualByComparingTo("100.00");
    }

    @Test void menuComponentsAreIncludedInUnitPrice() {
        OrderLine menu = line("15.000", "2");
        OrderLine comp = line("2.000", "1", "1.000"); // Double cheese +2, supplément fromage +1
        comp.setParentLine(menu); menu.getComponents().add(comp);
        pricing.computeLine(menu);
        assertThat(menu.getLineTotal()).isEqualByComparingTo("36.000");
    }

    @Test void orderTotalsWithLineAndOrderDiscountAndTax() {
        SaleOrder o = new SaleOrder();
        OrderLine a = line("10.000", "2"); a.setTaxRate(new BigDecimal("19")); a.setOrder(o);
        OrderLine b = line("5.000", "1"); b.setDiscountPercent(new BigDecimal("20")); b.setOrder(o);
        o.getLines().add(a); o.getLines().add(b);
        o.setDiscountPercent(new BigDecimal("10"));
        pricing.computeOrder(o);
        assertThat(o.getSubtotal()).isEqualByComparingTo("25.000");
        assertThat(o.getLineDiscountTotal()).isEqualByComparingTo("1.000");
        assertThat(o.getDiscountAmount()).isEqualByComparingTo("2.400");   // 10% of 24
        assertThat(o.getTotal()).isEqualByComparingTo("21.600");
        // tax: line a after pro-rata = 20 * 0.9 = 18 -> 18 - 18/1.19 = 2.874
        assertThat(o.getTaxTotal()).isEqualByComparingTo("2.874");
    }

    @Test void mixedPaymentScenario32500() {
        SaleOrder o = new SaleOrder();
        OrderLine chaw = line("7.500", "3"); chaw.setOrder(o);
        OrderLine tira = line("4.500", "2"); tira.setOrder(o);
        OrderLine eau = line("1.000", "1"); eau.setOrder(o);
        o.getLines().add(chaw); o.getLines().add(tira); o.getLines().add(eau);
        pricing.computeOrder(o);
        assertThat(o.getTotal()).isEqualByComparingTo("32.500");
        BigDecimal cash = new BigDecimal("20.000"), card = new BigDecimal("12.500");
        assertThat(cash.add(card)).isEqualByComparingTo(o.getTotal());
    }

    @Test void changeIsComputedFromTenderedCash() {
        assertThat(PricingService.change(new BigDecimal("32.500"), new BigDecimal("50"))).isEqualByComparingTo("17.500");
        assertThat(PricingService.change(new BigDecimal("28.000"), new BigDecimal("28.000"))).isEqualByComparingTo("0");
        assertThat(PricingService.change(new BigDecimal("28.000"), new BigDecimal("20"))).isEqualByComparingTo("0");
        assertThat(PricingService.change(new BigDecimal("28.000"), null)).isEqualByComparingTo("0");
    }

    @Test void moneyHelpers() {
        assertThat(Money.r(new BigDecimal("1.23456"))).isEqualByComparingTo("1.235");
        assertThat(Money.pct(new BigDecimal("33.333"), new BigDecimal("15"))).isEqualByComparingTo("5.000");
        assertThat(Money.taxIncluded(new BigDecimal("119"), new BigDecimal("19"))).isEqualByComparingTo("19.000");
        assertThat(Money.taxIncluded(new BigDecimal("10"), BigDecimal.ZERO)).isEqualByComparingTo("0");
    }
}
