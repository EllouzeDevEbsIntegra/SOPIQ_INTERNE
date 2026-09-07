package com.poscaisse.printing;

import com.poscaisse.domain.*;
import com.poscaisse.dto.RegisterDtos;
import com.poscaisse.service.Money;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.OffsetDateTime;
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
        c.put("showRegister", false); c.put("showServiceMode", true); c.put("showCustomer", true); c.put("showCourier", true);
        // Le prix unitaire chargeait le ticket sans etre reclame : il reste disponible dans
        // les reglages d'impression, mais un ticket neuf sort sans lui.
        c.put("showUnitPrice", false);
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

    /**
     * Emphase DANS une ligne, entre ces deux marqueurs. BOLD et HEAD valent pour la ligne
     * entiere ; la variante, elle, n'est qu'un mot au milieu d'un nom.
     *
     * Le passeur cherche la pate avant tout le reste : sur << 2 x Oml Moz Thon Cereale >>,
     * c'est le dernier mot qui decide de ce qu'il attrape, et c'est celui qui se perd dans
     * la ligne. En gras, il se lit sans lire le reste.
     *
     * Les deux caracteres choisis sont ceux que les imprimantes emploient depuis toujours
     * pour cela - SO et SI - et ils ne peuvent pas apparaitre dans un nom d'article.
     */
    public static final char EMPH_ON = '\u000E';
    public static final char EMPH_OFF = '\u000F';

    static boolean marqueur(char c) { return c == EMPH_ON || c == EMPH_OFF; }

    /** Longueur VISIBLE : les marqueurs ne prennent pas de place sur le papier. */
    static int vlen(String s) {
        int n = 0;
        for (int i = 0; i < s.length(); i++) if (!marqueur(s.charAt(i))) n++;
        return n;
    }

    static final class Sheet {
        final int w; final StringBuilder sb = new StringBuilder();
        Sheet(int w) { this.w = w; }
        void nl() { sb.append('\n'); }
        void line(String s) { for (String part : wrap(s, w)) sb.append(part).append('\n'); }
        void center(String s) { for (String part : wrap(s, w)) { int pad = Math.max(0, (w - vlen(part)) / 2); sb.append(" ".repeat(pad)).append(part).append('\n'); } }
        void sep(String ch) { sb.append((ch == null || ch.isEmpty() ? "-" : ch.substring(0, 1)).repeat(w)).append('\n'); }
        void lr(String l, String r) {
            // Quand les deux ne tiennent pas sur une ligne, le libelle garde la sienne et
            // la valeur s'aligne a droite en dessous. Rogner le libelle, comme le ferait
            // un simple remplissage, le rendrait illisible (« Clie / nt »).
            if (vlen(l) + vlen(r) + 1 > w) {
                line(l);
                if (vlen(r) > w) { line(r); return; }
                sb.append(" ".repeat(w - vlen(r))).append(r).append('\n');
                return;
            }
            sb.append(l).append(" ".repeat(Math.max(1, w - vlen(l) - vlen(r)))).append(r).append('\n');
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
                int pad = Math.max(0, (bw - vlen(part)) / 2);
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
                while (vlen(t) > w) {
                    int max = indexApres(t, w);
                    int cut = t.lastIndexOf(' ', max);
                    if (cut <= 0) cut = max;
                    out.add(t.substring(0, cut).stripTrailing());
                    t = t.substring(cut).stripLeading();
                }
                out.add(t);
            }
            /*
                Une coupure au milieu d'un passage en gras laisserait la premiere moitie
                ouverte et la seconde sans marqueur : on referme et on rouvre. Le cas est
                rare - la variante est le dernier mot d'un nom - mais il donnerait un
                ticket a moitie gras, ce qui se remarque plus qu'un ticket sans gras.
            */
            boolean ouvert = false;
            for (int i = 0; i < out.size(); i++) {
                String l = out.get(i);
                if (ouvert) l = EMPH_ON + l;
                boolean finitOuvert = ouvert;
                for (int k = 0; k < l.length(); k++) {
                    char c = l.charAt(k);
                    if (c == EMPH_ON) finitOuvert = true; else if (c == EMPH_OFF) finitOuvert = false;
                }
                if (finitOuvert) l = l + EMPH_OFF;
                out.set(i, l);
                ouvert = finitOuvert;
            }
            return out;
        }

        /** Index du caractere ou la largeur visible w est atteinte. */
        static int indexApres(String s, int w) {
            int n = 0;
            for (int i = 0; i < s.length(); i++) {
                if (!marqueur(s.charAt(i))) n++;
                if (n > w) return i;
            }
            return s.length();
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
            // L'enseigne s'aligne a droite, comme la date en dessous : elle borde le logo
            // pose a gauche. Le remplissage est calcule ici pour qu'un support qui ignore
            // le marqueur d'en-tete imprime la meme chose.
            if (company != null && on(cfg, "showCompanyName"))
                s.lr("", company.getTradeName() != null && !company.getTradeName().isBlank() ? company.getTradeName() : company.getName());
            if (t != null && t.getHeaderText() != null && !t.getHeaderText().isBlank()) s.center(t.getHeaderText());
            // Date et heure forment une seule mention, alignee a droite sous l'enseigne.
            String quand = dateStr.isEmpty() || timeStr.isEmpty() ? dateStr + timeStr : dateStr + " - " + timeStr;
            if (!quand.isEmpty()) s.lr("", quand);
        });
        s.sep(sepCh);

        // ---- identification du ticket ----
        if (duplicate && on(cfg, "showDuplicateLabel")) s.big("*** DUPLICATA ***");
        if (on(cfg, "showTicketNumber")) s.bold(numero(o, "-"));
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

            /*
                UN SEUL montant par ligne, dans la colonne de droite : le total de la ligne.

                Ce total contient DEJA les supplements. Les reimprimer a droite, sous lui,
                se lit comme une addition : « 1 x Chia Kwika 7,000 » puis
                « + Mozarilla 3arbi 3,000 » a fait compter 10,000 a un client, alors que
                7,000 valait deja 4,000 + 3,000. Les supplements gardent donc leur ligne,
                mais sans montant - ils disent CE QU'ON MANGE, pas ce qu'on paie en plus.

                Il n'y a pas de reglage pour revenir en arriere : un montant faux a la
                lecture n'est pas une preference d'affichage.
            */
            s.lr(qty(l.getQuantity()) + " x " + name, money(l.getLineTotal().add(l.getDiscountAmount()), dec));

            /*
                Le prix unitaire, lui, reste utile quand le client conteste « pourquoi 8,000
                pour deux ». On l'ecrit en toutes lettres, HORS de la colonne des montants :
                aligne a droite, il redeviendrait une addition apparente.
            */
            if (on2(cfg, "showUnitPrice") && l.getQuantity().compareTo(BigDecimal.ONE) != 0 && l.getComponents().isEmpty())
                s.line("   à " + money(unit, dec) + " l'unité");

            if (on(cfg, "showModifiers")) {
                for (OrderLineModifier m : l.getModifiers()) s.line("   + " + modLabel(m));
                for (OrderLine c : l.getComponents()) {
                    s.line("   • " + qty(c.getQuantity()) + " " + shortName(c));
                    for (OrderLineModifier m : c.getModifiers()) s.line("       + " + modLabel(m));
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
    // ---------- etat de caisse ----------
    /**
     * L'etat d'une caisse : le meme recapitulatif que l'ecran de cloture, sur du papier
     * a tickets.
     *
     * Il reprend l'ordre de l'ecran, ligne pour ligne - especes d'abord, recettes
     * ensuite - parce que c'est cet ordre-la que le caissier vient de lire. Un etat qui
     * range les memes chiffres autrement oblige a les rechercher un par un pour verifier
     * qu'il dit bien la meme chose.
     *
     * Il s'imprime avant ou apres la cloture : avant, il sert a compter ; apres, il porte
     * en plus le compte reel et l'ecart, et c'est la piece que le gerant garde.
     */
    public String sessionReport(RegisterSession s, RegisterDtos.SessionSummary sum, Company company, ReceiptTemplate t) {
        Map<String, Object> cfg = config(t);
        int w = columns(t == null ? 80 : t.getPaperWidth());
        int dec = company == null || company.getDecimals() == null ? 3 : company.getDecimals();
        String cur = company == null ? "DT" : company.getCurrencySymbol();
        String sepCh = String.valueOf(cfg.getOrDefault("separator", "-"));
        boolean cloturee = s.getStatus() == Enums.SessionStatus.CLOSED;
        Sheet p = new Sheet(w);

        var edite = OffsetDateTime.now().atZoneSameInstant(TZ);
        p.head(() -> {
            if (company != null && on(cfg, "showCompanyName"))
                p.lr("", company.getTradeName() != null && !company.getTradeName().isBlank() ? company.getTradeName() : company.getName());
            p.lr("", edite.format(DATE) + " - " + edite.format(TIME));
        });
        p.sep(sepCh);
        p.bold("ÉTAT DE CAISSE");
        p.lr("Caisse", s.getRegister().getName());
        p.lr("Caissier", s.getOpenedBy().getFullName());
        p.lr("Ouverte", s.getOpenedAt().atZoneSameInstant(TZ).format(DATE) + " " + s.getOpenedAt().atZoneSameInstant(TZ).format(TIME));
        if (cloturee && s.getClosedAt() != null)
            p.lr("Clôturée", s.getClosedAt().atZoneSameInstant(TZ).format(DATE) + " " + s.getClosedAt().atZoneSameInstant(TZ).format(TIME));
        else
            p.lr("État édité le", edite.format(DATE) + " " + edite.format(TIME));
        p.sep(sepCh);

        p.lr("Fond initial", money(sum.openingFloat(), dec));
        p.lr("+ Ventes espèces", money(sum.cashSales(), dec));
        p.lr("- Remboursements espèces", money(sum.cashRefunds(), dec));
        p.lr("+ Entrées de caisse", money(sum.cashIn(), dec));
        p.lr("- Sorties de caisse", money(sum.cashOut(), dec));
        p.lr("ESPÈCES THÉORIQUES", money(sum.expectedCash(), dec) + " " + cur);
        if (cloturee && s.getCountedCash() != null) {
            p.lr("Espèces comptées", money(s.getCountedCash(), dec) + " " + cur);
            BigDecimal ecart = Money.nz(s.getCashDifference());
            p.lr("ÉCART", (ecart.signum() > 0 ? "+" : "") + money(ecart, dec) + " " + cur);
        }
        p.sep(sepCh);

        /*
            Tout ce qui n'est PAS des especes, sous un seul titre.

            La version precedente listait << Carte bancaire >> en tete, puis un total
            << Autres paiements >> qui l'excluait, puis le detail ou la carte revenait -
            et les especes avec, alors qu'elles sont deja comptees plus haut, avec le
            fond de caisse. Trois lectures du meme chiffre, et un total qui ne
            correspondait a aucune des trois.

            Un titre, son total, son detail. Les especes restent ou elles doivent etre :
            en haut, dans le tiroir.
        */
        BigDecimal horsEspeces = Money.r(Money.nz(sum.cardSales()).add(Money.nz(sum.otherSales())));
        p.lr("AUTRES PAIEMENTS", money(horsEspeces, dec) + " " + cur);
        for (RegisterDtos.MethodTotal m : sum.byMethod())
            if (!"CASH".equals(m.kind())) p.lr("  . " + m.name(), money(m.amount(), dec));
        p.lr("Tickets / annulations", sum.ticketsCount() + " / " + sum.cancellationsCount());
        p.lr("Remises accordées", money(sum.discounts(), dec));
        p.lr("CHIFFRE D'AFFAIRES", money(sum.revenue(), dec) + " " + cur);
        /*
            Le benefice n'apparait que si un taux a ete pose au back-office. A zero, la
            ligne ne s'imprime pas : un << benefice 0,000 >> se lirait comme une journee
            sans marge, ce qui n'est pas ce que dit un reglage vide.
        */
        if (Money.isPositive(sum.marginPercent())) {
            p.sep(sepCh);
            p.lr("Marge appliquée", pourcentage(sum.marginPercent()) + " %");
            p.lr("BÉNÉFICE ESTIMÉ", money(sum.estimatedProfit(), dec) + " " + cur);
            p.line("Estimation : marge x chiffre d'affaires.");
        }
        if (notBlank(s.getClosingNote())) { p.sep(sepCh); p.line("Note : " + s.getClosingNote()); }
        p.sep(sepCh);
        p.center("Document interne");
        return p.toString();
    }

    /** << 25 >> et non << 25,000 >> : un taux se lit comme on l'a saisi. */
    static String pourcentage(BigDecimal v) {
        return v.stripTrailingZeros().toPlainString().replace('.', ',');
    }

    public String prepTicket(SaleOrder o, List<OrderLine> lines, PrintDestination dest, ReceiptTemplate t, Company company, boolean duplicate) {
        Map<String, Object> cfg = config(t);
        int w = columns(t == null ? 80 : t.getPaperWidth());
        int dec = company == null || company.getDecimals() == null ? 3 : company.getDecimals();
        String sepCh = String.valueOf(cfg.getOrDefault("separator", "-"));
        Sheet s = new Sheet(w);
        s.big(dest.getName());
        if (duplicate) s.big("*** DUPLICATA ***");
        s.sep("=");
        s.bold(numero(o, o.getHeldRef()));
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

    /**
     * Le numero tel qu'il doit se lire sur le papier : l'affichage retenu au moment de la
     * vente, sinon la reference. On relit ce qui a ete pose sur la commande, jamais le
     * reglage du jour - une reimpression doit ressortir le ticket que le client a garde.
     *
     * RIEN N'EST AJOUTE DEVANT. Le ticket imprimait autrefois un << N° >> en dur ; depuis
     * que l'exploitant choisit ce qui s'affiche, ce prefixe faisait doublon des qu'il en
     * mettait un lui-meme (<< N° N° 0001 >>). Ce qui est ecrit ici est exactement ce qui
     * a ete demande, mot pour mot - le libelle appartient au format d'affichage.
     */
    private static String numero(SaleOrder o, String defaut) {
        if (o.getTicketDisplay() != null && !o.getTicketDisplay().isBlank()) return o.getTicketDisplay();
        return o.getTicketNumber() == null ? defaut : o.getTicketNumber();
    }

    /** Comme {@link #on} mais par defaut a NON : pour ce qui charge le ticket sans etre reclame. */
    private static boolean on2(Map<String, Object> cfg, String k) { Object v = cfg.get(k); return Boolean.TRUE.equals(v) || "true".equals(String.valueOf(v)); }

    /**
     * Nom imprime d'une ligne : nom court de l'article s'il existe, puis la variante
     * vendue, en prefixe ou en suffixe selon l'axe.
     *
     * La variante entre DANS le nom, et non sur une ligne « + » en dessous : le client ne
     * commande pas « une pizza thon avec du large », il commande « une pizza thon large ».
     * Un supplement, lui, garde sa ligne - c'est un ajout, pas le produit.
     */
    private static String shortName(OrderLine l) {
        Product p = l.getProduct();
        String base = p != null && p.getShortName() != null && !p.getShortName().isBlank()
                ? p.getShortName() : l.getProductName();
        if (l.getVariantValueName() == null) return base;
        String mot = l.getVariantValueShortName() == null || l.getVariantValueShortName().isBlank()
                ? l.getVariantValueName() : l.getVariantValueShortName();
        boolean prefixe = l.getVariantValue() != null && l.getVariantValue().getVariant() != null
                && l.getVariantValue().getVariant().getNamePosition() == Enums.NamePosition.PREFIX;
        String gras = EMPH_ON + mot + EMPH_OFF;
        return prefixe ? gras + " " + base : base + " " + gras;
    }

    /** « Mozarilla » ou « 3 x Mozarilla » : la quantite n'apparait que si elle depasse 1. */
    private static String modLabel(OrderLineModifier m) {
        return m.getQuantity() > 1 ? m.getQuantity() + " x " + m.getModifierName() : m.getModifierName();
    }
}
