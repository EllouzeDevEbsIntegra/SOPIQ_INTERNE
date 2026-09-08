package com.poscaisse.service;

import com.poscaisse.domain.*;
import com.poscaisse.printing.ReceiptRenderer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ReceiptRendererTest {
    private final ReceiptRenderer renderer = new ReceiptRenderer(new ObjectMapper());

    /**
     * Le texte tel qu'il sort sur le papier : les marqueurs de mise en forme (ligne mise
     * en avant, en-tete, emphase dans la ligne) ne s'impriment pas, donc ils ne comptent
     * pas dans la largeur.
     */
    private static String printable(String line) {
        return line.replaceAll("[\\u0001\\u0002\\u000E\\u000F]", "");
    }

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
        for (String line : txt.split("\n")) assertThat(printable(line).length()).as("line: " + line).isLessThanOrEqualTo(42);
        assertThat(txt).doesNotContain("DUPLICATA");
    }

    /** Le numéro de ticket est la ligne mise en avant du corps du ticket. */
    @Test void ticketNumberIsEmphasised() {
        SaleOrder o = order();
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        List<String> emphasised = txt.lines().filter(l -> !l.isEmpty() && l.charAt(0) == ReceiptRenderer.BOLD)
                .map(l -> l.substring(1).trim()).toList();
        assertThat(emphasised).containsExactly("PV01-2026-000001");
    }

    /**
     * L'en-tête est un bloc à part : l'imprimante y pose le logo à gauche, l'enseigne
     * au-dessus de la date et de l'heure à sa droite. Le texte reste rempli pour la
     * largeur du papier, donc lisible tel quel si le support ignore le marqueur.
     */
    @Test void headerIsABlockOfTradeNameThenDateAndTime() {
        SaleOrder o = order();
        ReceiptTemplate t = new ReceiptTemplate(); t.setPaperWidth(80);
        String txt = renderer.customerReceipt(o, o.getCompany(), t, false, false);
        List<String> header = txt.lines().takeWhile(l -> !l.isEmpty() && l.charAt(0) == ReceiptRenderer.HEAD)
                .map(l -> l.substring(1)).toList();
        assertThat(header).hasSize(2);
        assertThat(header.get(0).trim()).isEqualTo("FAST FOOD DEMO");
        // Enseigne et date sont toutes deux alignees a droite : elles bordent le logo.
        assertThat(header.get(0)).endsWith("FAST FOOD DEMO");
        assertThat(header.get(1)).endsWith(LocalDate.now(ZoneId.of("Africa/Tunis"))
                .format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) + " - " + header.get(1).substring(header.get(1).length() - 5));
        assertThat(header.get(1)).matches(" +\\d{2}/\\d{2}/\\d{4} - \\d{2}:\\d{2}");
        assertThat(header.get(1).length()).isEqualTo(42);
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

    /**
     * Le bloc de paiement se lit en colonne : libellés au bord gauche, montants suivis
     * de la devise — y compris le reçu, qu'une indentation détachait de la colonne.
     */
    @Test void paymentBlockIsLeftAlignedAndCarriesTheCurrency() {
        SaleOrder o = order();
        ReceiptTemplate t = new ReceiptTemplate(); t.setPaperWidth(80);
        List<String> bloc = renderer.customerReceipt(o, o.getCompany(), t, false, false).lines()
                .filter(l -> l.startsWith("ESPÈCES") || l.startsWith("Reçu") || l.startsWith("RENDU")).toList();
        assertThat(bloc).hasSize(3);
        for (String l : bloc) {
            assertThat(l).as("libellé collé au bord gauche : " + l).doesNotStartWith(" ");
            assertThat(l).as("devise sur le montant : " + l).endsWith(" DT");
        }
    }

    /**
     * Le commentaire du ticket se lit avec le destinataire, avant les articles : place
     * après les totaux, personne ne l'aurait cherché là.
     */
    @Test void ticketNoteSitsUnderTheRecipient() {
        SaleOrder o = order();
        o.setCustomerName("Karim");
        o.setNote("Livrer avant 20 h, sonner deux fois");
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        assertThat(txt).contains("Note : Livrer avant 20 h, sonner deux fois");
        assertThat(txt.indexOf("Note :")).isGreaterThan(txt.indexOf("Karim"));
        assertThat(txt.indexOf("Note :")).isLessThan(txt.indexOf("Cheeseburger"));
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
        for (String line : txt.split("\n")) assertThat(printable(line).length()).isLessThanOrEqualTo(32);
    }

    /**
     * La variante vendue s'imprime en gras AU MILIEU du nom : sur « 2 x Oml Moz Thon
     * Cereale », c'est le dernier mot qui decide de ce que le passeur attrape, et c'est
     * celui qui se perd dans la ligne. Les marqueurs ne prennent pas de place : la
     * colonne des montants reste alignee sur celle des lignes sans variante.
     */
    @Test void variantWordIsPrintedInBold() {
        SaleOrder o = order();
        Variant axe = new Variant(); axe.setName("Pâte"); axe.setNamePosition(Enums.NamePosition.SUFFIX);
        VariantValue val = new VariantValue(); val.setVariant(axe); val.setName("Pâte Céréale"); val.setShortName("Cér");
        OrderLine l = o.getLines().get(0);
        l.setVariantValue(val); l.setVariantValueName(val.getName()); l.setVariantValueShortName(val.getShortName());

        ReceiptTemplate t = new ReceiptTemplate(); t.setPaperWidth(80);
        String txt = renderer.customerReceipt(o, o.getCompany(), t, false, false);
        String ligne = txt.lines().filter(x -> x.contains("Cheeseburger")).findFirst().orElseThrow();

        assertThat(ligne).contains(ReceiptRenderer.EMPH_ON + "Cér" + ReceiptRenderer.EMPH_OFF);
        assertThat(printable(ligne)).isEqualTo("2 x Cheeseburger Cér" + " ".repeat(42 - 20 - 6) + "17,000");
        for (String x : txt.split("\n")) assertThat(printable(x).length()).as("line: " + x).isLessThanOrEqualTo(42);
    }

    /** Sur 32 colonnes, une coupure au milieu du gras le referme et le rouvre. */
    @Test void boldSurvivesAWrap() {
        SaleOrder o = order();
        Variant axe = new Variant(); axe.setName("Pâte"); axe.setNamePosition(Enums.NamePosition.SUFFIX);
        VariantValue val = new VariantValue(); val.setVariant(axe); val.setName("Pâte Céréale complète");
        OrderLine l = o.getLines().get(0);
        l.setProductName("Omelette Mozarilla Thon Merguez");
        l.getProduct().setShortName("Omelette Mozarilla Thon Merguez");
        l.setVariantValue(val); l.setVariantValueName(val.getName());

        ReceiptTemplate t = new ReceiptTemplate(); t.setPaperWidth(58);
        String txt = renderer.customerReceipt(o, o.getCompany(), t, false, false);
        for (String x : txt.split("\n")) {
            assertThat(printable(x).length()).as("line: " + x).isLessThanOrEqualTo(32);
            long on = x.chars().filter(c -> c == ReceiptRenderer.EMPH_ON).count();
            long off = x.chars().filter(c -> c == ReceiptRenderer.EMPH_OFF).count();
            assertThat(on).as("gras ouvert puis referme sur la meme ligne : " + x).isEqualTo(off);
        }
        assertThat(printable(txt)).contains("Pâte Céréale");
    }

    @Test void prepTicketHidesPricesByDefault() {
        SaleOrder o = order();
        PrintDestination d = new PrintDestination(); d.setName("Cuisine"); d.setShowPrices(false);
        String txt = renderer.prepTicket(o, List.copyOf(o.getLines()), d, new ReceiptTemplate(), o.getCompany(), false);
        assertThat(txt).contains("CUISINE").contains("2 x CHEESEBURGER").contains("Supplément fromage").doesNotContain("17,000");
    }

    /**
     * LE TICKET D'UNE VENTE AU POIDS.
     *
     * Ce que ce test protege : qu'un client qui relit son ticket retrouve son compte. Sans
     * l'unite, la ligne dit << 0,3 x Baklawa amande 17,400 >> - un nombre d'articles qui
     * ne veut rien dire, et un montant qu'on ne peut pas verifier. Avec elle, tout se lit :
     * 0,3 kg, a 58,000 le kg.
     *
     * Le prix au kilo s'ecrit MEME quand on a vendu un kilo juste : c'est la question que
     * pose le client suivant, et la reponse doit etre sur le papier.
     */
    private SaleOrder venteAuPoids(String poids) {
        SaleOrder o = order();
        o.getLines().clear();
        Category cat = new Category(); cat.setName("Pâtisserie orientale");
        Product p = new Product(); p.setName("Baklawa amande"); p.setShortName("Baklawa amande");
        p.setCategory(cat); p.setUnite(Enums.Unite.KG);
        OrderLine l = new OrderLine(); l.setOrder(o); l.setProduct(p); l.setProductName("Baklawa amande");
        l.setQuantity(new BigDecimal(poids)); l.setUnite(Enums.Unite.KG);
        l.setUnitPrice(new BigDecimal("58.000")); l.setOriginalUnitPrice(l.getUnitPrice());
        o.getLines().add(l);
        o.getPayments().clear();
        new PricingService().computeOrder(o);
        return o;
    }

    @Test void leTicketDitLePoidsEtLePrixDuKilo() {
        SaleOrder o = venteAuPoids("0.300");
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        assertThat(txt).contains("0,300 kg x Baklawa amande");
        assertThat(txt).contains("à 58,000 le kg");
        assertThat(txt).as("300 g a 58 DT le kilo").contains("17,400");
        assertThat(txt).as("une ligne pesée compte pour un article, jamais zéro").contains("Articles").doesNotContain("Articles                                 0");
        for (String line : txt.split("\n")) assertThat(printable(line).length()).as("line: " + line).isLessThanOrEqualTo(42);
    }

    @Test void lePrixDuKiloEstEcritMemePourUnKiloJuste() {
        SaleOrder o = venteAuPoids("1");
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        assertThat(txt).contains("1 kg x Baklawa amande").contains("à 58,000 le kg");
    }

    /** Ce qui se compte n'a pas d'unite a trainer : << 2 x Cheeseburger >>, comme avant. */
    @Test void ceQuiSeCompteResteInchange() {
        SaleOrder o = order();
        String txt = renderer.customerReceipt(o, o.getCompany(), new ReceiptTemplate(), false, false);
        assertThat(txt).contains("2 x Cheeseburger").doesNotContain("2 kg").doesNotContain("l'unité kg");
    }
}
