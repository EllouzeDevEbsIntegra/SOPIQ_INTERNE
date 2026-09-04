package com.poscaisse.printing;

import com.poscaisse.domain.*;
import com.poscaisse.service.Money;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Renders plain-text tickets (monospace) that fit 58 mm (32 cols) or 80 mm (42 cols) thermal paper.
 * Text output is printer-agnostic: the browser prints it today, an ESC/POS driver can send it tomorrow.
 */
@Component @RequiredArgsConstructor
public class ReceiptRenderer {
    private final ObjectMapper objectMapper;
    private static final ZoneId TZ = ZoneId.of("Africa/Tunis");
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm");

    public static Map<String, Object> defaultConfig() {
        Map<String, Object> c = new LinkedHashMap<>();
        c.put("showTicketNumber", true); c.put("showDate", true); c.put("showTime", true); c.put("showCashier", true);
        c.put("showRegister", false); c.put("showServiceMode", true); c.put("showCustomer", true); c.put("showCourier", true); c.put("showUnitPrice", true);
        c.put("showModifiers", true); c.put("showDiscounts", true); c.put("showTaxes", false); c.put("showSubtotal", true);
        c.put("showPayments", true); c.put("showChange", true); c.put("showCompanyName", true); c.put("showAddress", true);
        c.put("showPhone", true); c.put("showTaxId", true); c.put("separator", "-"); c.put("showItemCount", true);
        c.put("showDuplicateLabel", true); c.put("prepShowTime", true); c.put("prepBigQuantities", true);
        return c;
    }

    public Map<String, Object> config(ReceiptTemplate t) {
        Map<String, Object> c = defaultConfig();
        try {
            if (t != null && t.getConfigJson() != null && !t.getConfigJson().isBlank())
                c.putAll(objectMapper.readValue(t.getConfigJson(), new TypeReference<Map<String, Object>>() {}));
        } catch (Exception ignored) {}
        return c;
    }

    public static int columns(int paperWidth) { return paperWidth <= 58 ? 32 : 42; }

    public static String money(BigDecimal v, int decimals) {
        DecimalFormatSymbols s = new DecimalFormatSymbols(Locale.FRANCE);
        s.setGroupingSeparator(' '); s.setDecimalSeparator(',');
        DecimalFormat f = new DecimalFormat("#,##0." + "0".repeat(Math.max(0, decimals)), s);
        return f.format(v == null ? BigDecimal.ZERO : v);
    }

    // ---------- text helpers ----------
    /** Marqueur de ligne mise en avant, en tete de ligne ; invisible en texte brut. */
    public static final char BOLD = '\u0001';

    /**
     * Marqueur des lignes de l'en-tete. L'imprimante les dispose a droite du logo :
     * l'enseigne au-dessus, la date et l'heure en dessous. Le texte reste rempli pour
     * la largeur du papier, donc parfaitement lisible sur un support qui ignore le
     * marqueur (texte brut, ESC/POS d'aujourd'hui).
     */
    public static final char HEAD = '\u0002';

    static final class Sheet {
        final int w; final StringBuilder sb = new StringBuilder();
        Sheet(int w) { this.w = w; }
        void nl() { sb.append('\n'); }
        void line(String s) { for (String part : wrap(s, w)) sb.append(part).append('\n'); }
        void center(String s) { for (String part : wrap(s, w)) { int pad = Math.max(0, (w - part.length()) / 2); sb.append(" ".repeat(pad)).append(part).append('\n'); } }
        void sep(String ch) { sb.append((ch == null || ch.isEmpty() ? "-" : ch.substring(0, 1)).repeat(w)).append('\n'); }
        void lr(String l, String r) {
            // Quand les deux ne tiennent pas sur une ligne, le libelle garde la sienne et
            // la valeur s'aligne a droite en dessous. Rogner le libelle, comme le ferait
            // un simple remplissage, le rendrait illisible (« Clie / nt »).
            if (l.length() + r.length() + 1 > w) {
                line(l);
                if (r.length() > w) { line(r); return; }
                sb.append(" ".repeat(w - r.length())).append(r).append('\n');
                return;
            }
            sb.append(l).append(" ".repeat(Math.max(1, w - l.length() - r.length()))).append(r).append('\n');
        }
        void big(String s) { center(s.toUpperCase()); }
        /**
         * Ligne mise en avant : double hauteur et gras. Elle porte un marqueur en tete,
         * que l'imprimante (navigateur aujourd'hui, ESC/POS demain) traduit dans sa propre
         * mise en forme. Le texte est donc calibre sur la moitie des colonnes, puisqu'un
         * caractere double largeur occupe la place de deux.
         */
        void bold(String s) {
            int bw = Math.max(8, w / 2);
            for (String part : wrap(s, bw)) {
                int pad = Math.max(0, (bw - part.length()) / 2);
                sb.append(BOLD).append(" ".repeat(pad)).append(part).append('\n');
            }
        }
        /** Marque comme lignes d'en-tete tout ce que le bloc vient d'ecrire. */
        void head(Runnable emit) {
            int from = sb.length();
            emit.run();
            String block = sb.substring(from);
            sb.setLength(from);
            for (String l : block.split("\n")) sb.append(HEAD).append(l).append('\n');
        }
        static List<String> wrap(String s, int w) {
            List<String> out = new ArrayList<>();
            if (s == null) { out.add(""); return out; }
            for (String raw : s.split("\n")) {
                String t = raw;
                while (t.length() > w) {
                    int cut = t.lastIndexOf(' ', w);
                    if (cut <= 0) cut = w;
                    out.add(t.substring(0, cut).stripTrailing());
                    t = t.substring(cut).stripLeading();
                }
                out.add(t);
            }
            return out;
        }
        @Override public String toString() { return sb.toString(); }
    }

    private static String mode(Enums.ServiceMode m) {
        return switch (m) { case DINE_IN -> "SUR PLACE"; case TAKEAWAY -> "À EMPORTER"; case DELIVERY -> "LIVRAISON"; };
    }

    private static String qty(BigDecimal q) {
        return q.stripTrailingZeros().scale() <= 0 ? q.stripTrailingZeros().toPlainString() : q.toPlainString();
    }

    // ---------- customer receipt ----------
    public String customerReceipt(SaleOrder o, Company company, ReceiptTemplate t, boolean duplicate, boolean taxEnabled) {
        Map<String, Object> cfg = config(t);
        int w = columns(t == null ? 80 : t.getPaperWidth());
        int dec = company == null || company.getDecimals() == null ? 3 : company.getDecimals();
        String cur = company == null ? "DT" : company.getCurrencySymbol();
        String sepCh = String.valueOf(cfg.getOrDefault("separator", "-"));
        Sheet s = new Sheet(w);
        // ---- en-tete : le logo a gauche, l'enseigne et la date/heure a sa droite ----
        // L'adresse et le telephone sont renvoyes en pied : les repeter en haut allongerait
        // le ticket sans rien apprendre au client qui est deja dans le restaurant.
        var when = (o.getPaidAt() == null ? o.getCreatedAt() : o.getPaidAt()).atZoneSameInstant(TZ);
        String dateStr = on(cfg, "showDate") ? when.format(DATE) : "";
        String timeStr = on(cfg, "showTime") ? when.format(TIME) : "";
        s.head(() -> {
            if (company != null && on(cfg, "showCompanyName"))
                s.center(company.getTradeName() != null && !company.getTradeName().isBlank() ? company.getTradeName() : company.getName());
            if (t != null && t.getHeaderText() != null && !t.getHeaderText().isBlank()) s.center(t.getHeaderText());
            if (!dateStr.isEmpty() && !timeStr.isEmpty()) s.lr(dateStr, timeStr);
            else if (!dateStr.isEmpty() || !timeStr.isEmpty()) s.center(dateStr + timeStr);
        });
        s.sep(sepCh);

        // ---- identification du ticket ----
        if (duplicate && on(cfg, "showDuplicateLabel")) s.big("*** DUPLICATA ***");
        if (on(cfg, "showTicketNumber")) s.bold("N° " + (o.getTicketNumber() == null ? "-" : o.getTicketNumber()));
        String cashier = on(cfg, "showCashier") ? o.getCashier().getFullName() : null;
        String service = on(cfg, "showServiceMode") ? mode(o.getServiceMode()) : null;
        // Caissier et service tiennent sur une ligne quand la largeur le permet : une ligne
        // de moins par ticket, c'est plusieurs metres de papier sur une annee.
        if (cashier != null && service != null && ("Caissier : " + cashier).length() + service.length() + 1 <= w)
            s.lr("Caissier : " + cashier, service);
        else {
            if (cashier != null) s.lr("Caissier", cashier);
            if (service != null) s.lr("Service", service);
        }
        if (on(cfg, "showRegister")) s.lr("Caisse", o.getRegister().getName());
        if (on(cfg, "showCustomer") && o.getCustomerName() != null && !o.getCustomerName().isBlank())
            s.lr("Client", o.getCustomerName() + (o.getCustomerPhone() == null ? "" : " " + o.getCustomerPhone()));
        if (on(cfg, "showCourier") && o.getCourier() != null) s.lr("Livreur", o.getCourier().getName());
        // Le commentaire du ticket suit le destinataire : il le concerne le plus souvent
        // (une consigne de livraison, un numero de table) et doit se lire avant les
        // articles, pas apres les totaux ou personne ne le cherche.
        if (notBlank(o.getNote())) s.line("Note : " + o.getNote());
        s.sep(sepCh);
        int count = 0;
        for (OrderLine l : o.getLines()) {
            if (l.getParentLine() != null) continue;
            count += l.getQuantity().intValue();
            String name = shortName(l);
            BigDecimal unit = l.getUnitPrice().add(l.getModifiersTotal());
            String left = qty(l.getQuantity()) + " x " + name;
            if (on(cfg, "showUnitPrice") && l.getQuantity().compareTo(BigDecimal.ONE) != 0 && l.getComponents().isEmpty()) {
                s.line(left + " @ " + money(unit, dec));
                s.lr("", money(l.getLineTotal().add(l.getDiscountAmount()), dec));
            } else {
                s.lr(left, money(l.getLineTotal().add(l.getDiscountAmount()), dec));
            }
            if (on(cfg, "showModifiers")) {
                for (OrderLineModifier m : l.getModifiers())
                    s.lr("   + " + modLabel(m), modAmount(m).signum() == 0 ? "" : money(modAmount(m), dec));
                for (OrderLine c : l.getComponents()) {
                    s.lr("   • " + qty(c.getQuantity()) + " " + shortName(c), c.getLineTotal().signum() == 0 ? "" : "+" + money(c.getLineTotal(), dec));
                    for (OrderLineModifier m : c.getModifiers()) s.lr("       + " + modLabel(m), modAmount(m).signum() == 0 ? "" : money(modAmount(m), dec));
                }
            }
            if (on(cfg, "showDiscounts") && l.getDiscountAmount().signum() > 0) s.lr("   Remise " + l.getDiscountPercent().stripTrailingZeros().toPlainString() + "%", "-" + money(l.getDiscountAmount(), dec));
            if (l.getNote() != null && !l.getNote().isBlank()) s.line("   » " + l.getNote());
        }
        s.sep(sepCh);
        if (on(cfg, "showItemCount")) s.lr("Articles", String.valueOf(count));
        boolean hasDisc = o.getDiscountAmount().signum() > 0 || o.getLineDiscountTotal().signum() > 0;
        if (on(cfg, "showSubtotal") && hasDisc) s.lr("SOUS-TOTAL", money(o.getSubtotal(), dec));
        if (on(cfg, "showDiscounts") && o.getLineDiscountTotal().signum() > 0) s.lr("Remises lignes", "-" + money(o.getLineDiscountTotal(), dec));
        if (on(cfg, "showDiscounts") && o.getDiscountAmount().signum() > 0) s.lr("REMISE " + o.getDiscountPercent().stripTrailingZeros().toPlainString() + "%", "-" + money(o.getDiscountAmount(), dec));
        s.lr("TOTAL", money(o.getTotal(), dec) + " " + cur);
        if (taxEnabled && on(cfg, "showTaxes")) { s.lr("  dont TVA", money(o.getTaxTotal(), dec)); s.lr("  Hors taxes", money(o.getTotal().subtract(o.getTaxTotal()), dec)); }
        if (on(cfg, "showPayments") && !o.getPayments().isEmpty()) {
            s.sep(sepCh);
            // Moyen, recu et rendu forment un meme bloc : memes libelles au bord gauche et
            // memes montants suivis de la devise, pour se lire d'un coup d'oeil a la remise
            // de la monnaie. Indenter « Recu » le detachait de la colonne.
            for (Payment p : o.getPayments()) {
                s.lr(p.getPaymentMethod().getName().toUpperCase(), money(p.getAmount(), dec) + " " + cur);
                if (p.getTendered() != null && p.getTendered().compareTo(p.getAmount()) > 0)
                    s.lr("Reçu", money(p.getTendered(), dec) + " " + cur);
            }
            if (on(cfg, "showChange") && o.getChangeAmount().signum() > 0) s.lr("RENDU", money(o.getChangeAmount(), dec) + " " + cur);
        }
        if (o.getStatus() == Enums.OrderStatus.CANCELLED) { s.sep(sepCh); s.big("TICKET ANNULÉ"); }
        else if (o.getRefundedTotal() != null && o.getRefundedTotal().signum() > 0) { s.sep(sepCh); s.lr("REMBOURSÉ", money(o.getRefundedTotal(), dec)); }
        // ---- pied : remerciement, puis les coordonnees pour recommander ----
        s.sep(sepCh);
        String merci = t != null && t.getFooterText() != null && !t.getFooterText().isBlank()
                ? t.getFooterText() : "Merci pour votre visite";
        s.center(merci);
        if (company != null) {
            if (on(cfg, "showAddress") && notBlank(company.getAddress())) s.center(company.getAddress());
            if (on(cfg, "showPhone") && notBlank(company.getPhone())) s.center("Tél : " + company.getPhone());
            if (on(cfg, "showTaxId") && notBlank(company.getTaxId())) s.center("MF : " + company.getTaxId());
        }
        s.nl();
        return s.toString();
    }

    // ---------- preparation ticket ----------
    public String prepTicket(SaleOrder o, List<OrderLine> lines, PrintDestination dest, ReceiptTemplate t, Company company, boolean duplicate) {
        Map<String, Object> cfg = config(t);
        int w = columns(t == null ? 80 : t.getPaperWidth());
        int dec = company == null || company.getDecimals() == null ? 3 : company.getDecimals();
        String sepCh = String.valueOf(cfg.getOrDefault("separator", "-"));
        Sheet s = new Sheet(w);
        s.big(dest.getName());
        if (duplicate) s.big("*** DUPLICATA ***");
        s.sep("=");
        s.bold("N° " + (o.getTicketNumber() == null ? o.getHeldRef() : o.getTicketNumber()));
        var when = (o.getPaidAt() == null ? o.getCreatedAt() : o.getPaidAt()).atZoneSameInstant(TZ);
        if (on(cfg, "prepShowTime")) s.lr(when.format(DATE), when.format(TIME));
        s.lr("Service", mode(o.getServiceMode()));
        if (o.getCustomerName() != null && !o.getCustomerName().isBlank()) s.lr("Client", o.getCustomerName());
        if (o.getCourier() != null) s.lr("Livreur", o.getCourier().getName());
        s.sep(sepCh);
        for (OrderLine l : lines) {
            String q = qty(l.getQuantity());
            String name = shortName(l);
            if (dest.isShowPrices()) s.lr(q + " x " + name, money(l.getLineTotal(), dec)); else s.line(q + " x " + name.toUpperCase());
            for (OrderLineModifier m : l.getModifiers()) s.line("    + " + modLabel(m));
            for (OrderLine c : l.getComponents()) {
                s.line("    • " + qty(c.getQuantity()) + " " + shortName(c));
                for (OrderLineModifier m : c.getModifiers()) s.line("        + " + modLabel(m));
            }
            if (l.getNote() != null && !l.getNote().isBlank()) s.line("    » " + l.getNote().toUpperCase());
            s.nl();
        }
        if (o.getNote() != null && !o.getNote().isBlank()) { s.sep(sepCh); s.line("NOTE : " + o.getNote().toUpperCase()); }
        s.sep("=");
        s.nl();
        return s.toString();
    }

    private static boolean notBlank(String v) { return v != null && !v.isBlank(); }

    private static boolean on(Map<String, Object> cfg, String k) { Object v = cfg.get(k); return v == null || Boolean.TRUE.equals(v) || "true".equals(String.valueOf(v)); }

    private static String shortName(OrderLine l) {
        Product p = l.getProduct();
        if (p != null && p.getShortName() != null && !p.getShortName().isBlank()) return p.getShortName();
        return l.getProductName();
    }

    /** « Mozarilla » ou « 3 x Mozarilla » : la quantite n'apparait que si elle depasse 1. */
    private static String modLabel(OrderLineModifier m) {
        return m.getQuantity() > 1 ? m.getQuantity() + " x " + m.getModifierName() : m.getModifierName();
    }

    /** Montant reellement facture pour l'option : le supplement multiplie par sa quantite. */
    private static BigDecimal modAmount(OrderLineModifier m) {
        return Money.nz(m.getPriceDelta()).multiply(BigDecimal.valueOf(Math.max(1, m.getQuantity())));
    }
}
