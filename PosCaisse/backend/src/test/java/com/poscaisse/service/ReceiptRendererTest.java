package com.poscaisse.service;

import com.poscaisse.domain.*;
import com.poscaisse.printing.ReceiptRenderer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ReceiptRendererTest {
    private final ReceiptRenderer renderer = new ReceiptRenderer(new ObjectMapper());

    private SaleOrder order() {
        Company c = new Company(); c.setName("FAST FOOD DEMO SARL"); c.setTradeName("FAST FOOD DEMO"); c.setAddress("Tunis"); c.setPhone("71 000 000"); c.setDecimals(3);
        PointOfSale pos = new PointOfSale(); pos.setCode("PV01"); pos.setName("CENTRE-VILLE");
        Register r = new Register(); r.setCode("C01"); r.setName("CAISSE 01"); r.setPointOfSale(pos);
        User u = new User(); u.setFullName("Ahmed");
        SaleOrder o = new SaleOrder(); o.setTicketNumber("PV01-2026-000001"); o.setRegister(r); o.setCashier(u); o.setPointOfSale(pos); o.setStatus(Enums.OrderStatus.PAID); o.setPaidAt(OffsetDateTime.now());
        Category cat = new Category(); cat.setName("Burgers");
        Product p = new Product(); p.setName("Cheeseburger"); p.setShortName("Cheeseburger"); p.setCategory(cat);
        OrderLine l = new OrderLine(); l.setOrder(o); l.setProduct(p); l.setProductName("Cheeseburger"); l.setQuantity(new BigDecimal("2")); l.setUnitPrice(new BigDecimal("7.500")); l.setOriginalUnitPrice(l.getUnitPrice());
        OrderLineModifier m = new OrderLineModifier(); m.setModifierName("Supplément fromage"); m.setPriceDelta(new BigDecimal("1.000")); l.getModifiers().add(m);
        o.getLines().add(l);
        new PricingService().computeOrder(o);
        PaymentMethod cash = new PaymentMethod(); cash.setName("Espèces"); cash.setKind(Enums.PaymentKind.CASH);
        Payment pay = new Payment(); pay.setPaymentMethod(cash); pay.setAmount(o.getTotal()); pay.setTendered(new BigDecimal("50")); pay.setChangeGiven(new BigDecimal("50").subtract(o.getTotal()));
        o.getPayments().add(pay); o.setChangeAmount(pay.getChangeGiven()); o.setCompany(c);
        return o;
    }

    @Test void customerReceiptFits80mmAndShowsTotals() {
        SaleOrder o = order();
        ReceiptTemplate t = new ReceiptTemplate(); t.setPaperWidth(80); t.setFooterText("Merci");
        String txt = renderer.customerReceipt(o, o.getCompany(), t, false, false);
        assertThat(txt).contains("PV01-2026-000001").contains("Cheeseburger").contains("Supplément fromage").contains("17,000").contains("TOTAL").contains("RENDU").contains("33,000").contains("Merci");
        for (String line : txt.split("\n")) assertThat(line.length()).as("line: " + line).isLessThanOrEqualTo(42);
        assertThat(txt).doesNotContain("DUPLICATA");
    }

    /** Le numéro de ticket et l'enseigne sont les deux lignes mises en avant. */
    @Test void ticketNumberAndTradeNameAreEmphasised() {
        SaleOrder o = order();
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        List<String> emphasised = txt.lines().filter(l -> !l.isEmpty() && l.charAt(0) == ReceiptRenderer.BOLD)
                .map(l -> l.substring(1).trim()).toList();
        assertThat(emphasised).containsExactly("FAST FOOD DEMO", "N° PV01-2026-000001");
    }

    /**
     * L'adresse et le téléphone sont en pied, pas en en-tête : un ticket court est
     * l'objet même de cette mise en page.
     */
    @Test void addressAndPhoneSitInTheFooter() {
        SaleOrder o = order();
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        assertThat(txt.indexOf("Tunis")).isGreaterThan(txt.indexOf("TOTAL"));
        assertThat(txt.indexOf("71 000 000")).isGreaterThan(txt.indexOf("TOTAL"));
        // Sans texte de pied configuré, le remerciement par défaut est imprimé.
        assertThat(txt).contains("Merci pour votre visite");
    }

    /** Un ticket en livraison nomme le livreur qui l'emporte. */
    @Test void deliveryTicketNamesTheCourier() {
        SaleOrder o = order();
        o.setServiceMode(Enums.ServiceMode.DELIVERY);
        Courier c = new Courier(); c.setName("Mohamed"); o.setCourier(c);
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        assertThat(txt).contains("LIVRAISON").contains("Livreur").contains("Mohamed");
    }

    @Test void receipt58mmWrapsAndDuplicateLabel() {
        SaleOrder o = order();
        ReceiptTemplate t = new ReceiptTemplate(); t.setPaperWidth(58);
        String txt = renderer.customerReceipt(o, o.getCompany(), t, true, false);
        assertThat(txt).contains("DUPLICATA");
        for (String line : txt.split("\n")) assertThat(line.length()).isLessThanOrEqualTo(32);
    }

    @Test void prepTicketHidesPricesByDefault() {
        SaleOrder o = order();
        PrintDestination d = new PrintDestination(); d.setName("Cuisine"); d.setShowPrices(false);
        String txt = renderer.prepTicket(o, List.copyOf(o.getLines()), d, new ReceiptTemplate(), o.getCompany(), false);
        assertThat(txt).contains("CUISINE").contains("2 x CHEESEBURGER").contains("Supplément fromage").doesNotContain("17,000");
    }
}
