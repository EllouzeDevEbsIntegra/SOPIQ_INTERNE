package com.poscaisse.printing;

import com.poscaisse.domain.Company;
import com.poscaisse.dto.AccountDtos.StatementDto;
import com.poscaisse.dto.AccountDtos.StatementPaymentDto;
import com.poscaisse.dto.AccountDtos.StatementTicketDto;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Relevé de compte en PDF, prêt à archiver, à envoyer ou à imprimer sur une A4.
 *
 * Le document est produit ici et non dans le navigateur pour deux raisons : les montants
 * sont ceux que le serveur a calculés, sans risque d'écart avec l'écran ; et la caisse
 * tourne dans un navigateur lancé en impression directe (`--kiosk-printing`), où un
 * `window.print()` partirait droit sur l'imprimante à tickets. Un fichier téléchargé
 * laisse l'utilisateur libre de l'ouvrir, de l'imprimer où il veut ou de le joindre à
 * un courriel.
 */
@Component
public class StatementPdf {
    private static final ZoneId TZ = ZoneId.of("Africa/Tunis");
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter STAMP = DateTimeFormatter.ofPattern("dd/MM/yyyy 'à' HH:mm");
    private static final DateTimeFormatter ROW = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private static final PDFont REGULAR = new PDType1Font(FontName.HELVETICA);
    private static final PDFont BOLD = new PDType1Font(FontName.HELVETICA_BOLD);

    private static final float MARGIN = 40f;
    private static final float BOTTOM = 52f;

    /** Une colonne du tableau : intitulé, largeur en points, et alignement. */
    private record Col(String title, float width, boolean right) {}

    public byte[] render(StatementDto st, Company company, OffsetDateTime from, OffsetDateTime to, String editedBy) {
        int dec = company == null || company.getDecimals() == null ? 3 : company.getDecimals();
        String cur = company == null || company.getCurrencySymbol() == null ? "DT" : company.getCurrencySymbol();
        boolean courier = "COURIER".equals(st.party());

        try (PDDocument doc = new PDDocument(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Page p = new Page(doc);
            float w = PDRectangle.A4.getWidth() - 2 * MARGIN;

            // ---- en-tete ----
            if (company != null) {
                p.text(BOLD, 16, MARGIN, name(company));
                p.moveDown(14);
                String coords = join(" · ", company.getAddress(), company.getPhone() == null ? null : "Tél " + company.getPhone(),
                        company.getTaxId() == null ? null : "MF " + company.getTaxId());
                if (!coords.isEmpty()) { p.text(REGULAR, 8.5f, MARGIN, coords); p.moveDown(6); }
            }
            p.right(BOLD, 13, MARGIN + w, courier ? "RELEVÉ DE COMPTE LIVREUR" : "RELEVÉ DE COMPTE CLIENT", p.y() + (company == null ? 0 : 20));
            p.moveDown(14);
            p.rule(MARGIN, MARGIN + w);
            p.moveDown(16);

            // ---- titulaire et periode ----
            p.text(BOLD, 13, MARGIN, st.name());
            if (st.phone() != null && !st.phone().isBlank()) p.right(REGULAR, 9.5f, MARGIN + w, "Tél " + st.phone(), p.y());
            p.moveDown(13);
            p.text(REGULAR, 9, MARGIN, "Période : " + period(from, to));
            p.right(REGULAR, 8, MARGIN + w, "Édité le " + OffsetDateTime.now().atZoneSameInstant(TZ).format(STAMP)
                    + (editedBy == null ? "" : " par " + editedBy), p.y());
            p.moveDown(20);

            // ---- resume ----
            float boxW = (w - 16) / 3;
            summary(p, MARGIN, boxW, courier ? "Total des courses" : "Total des tickets", money(st.totalTickets(), dec, cur), false);
            summary(p, MARGIN + boxW + 8, boxW, "Total des règlements", money(st.totalPayments(), dec, cur), false);
            summary(p, MARGIN + 2 * (boxW + 8), boxW, "Solde restant", money(st.balance(), dec, cur), true);
            p.moveDown(56);

            // ---- tickets ----
            List<Col> tCols = List.of(new Col("Date", 90, false), new Col("N° ticket", 105, false),
                    new Col("Commentaire", w - 90 - 105 - 55 - 85, false), new Col("Qté", 55, true), new Col("Total TTC", 85, true));
            p.section(BOLD, 11, MARGIN, courier ? "Courses confiées" : "Tickets portés au compte");
            List<String[]> tRows = new ArrayList<>();
            for (StatementTicketDto t : st.tickets())
                tRows.add(new String[]{ t.date().atZoneSameInstant(TZ).format(ROW), t.ticketNumber(),
                        t.note() == null ? "" : t.note(), qty(t.quantity()), ReceiptRenderer.money(t.total(), dec) });
            table(p, tCols, tRows, "Aucun ticket sur la période.");
            total(p, w, courier ? "Total des courses" : "Total des tickets", money(st.totalTickets(), dec, cur));
            p.moveDown(24);

            // ---- reglements ----
            List<Col> rCols = List.of(new Col("Date", 90, false), new Col("N° règlement", 105, false),
                    new Col("Moyen", 95, false), new Col("Commentaire", w - 90 - 105 - 95 - 85, false), new Col("Montant", 85, true));
            p.section(BOLD, 11, MARGIN, "Règlements");
            List<String[]> rRows = new ArrayList<>();
            for (StatementPaymentDto x : st.payments())
                rRows.add(new String[]{ x.date().atZoneSameInstant(TZ).format(ROW), x.number(), x.method(),
                        x.note() == null ? "" : x.note(), ReceiptRenderer.money(x.amount(), dec) });
            table(p, rCols, rRows, "Aucun règlement sur la période.");
            total(p, w, "Total des règlements", money(st.totalPayments(), dec, cur));
            p.moveDown(22);

            // ---- solde ----
            p.rule(MARGIN, MARGIN + w);
            p.moveDown(16);
            p.text(BOLD, 12, MARGIN, "SOLDE RESTANT DÛ");
            p.right(BOLD, 14, MARGIN + w, money(st.balance(), dec, cur), p.y());

            p.close();
            paginate(doc);
            doc.save(out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("Génération du relevé PDF impossible.", e);
        }
    }

    /** Nom du fichier proposé au téléchargement. */
    public static String fileName(StatementDto st) {
        String base = ("COURIER".equals(st.party()) ? "releve-livreur-" : "releve-client-") + st.name();
        return base.toLowerCase().replaceAll("[^a-z0-9]+", "-").replaceAll("(^-|-$)", "")
                + "-" + java.time.LocalDate.now(TZ) + ".pdf";
    }

    // ---------- blocs ----------

    private void summary(Page p, float x, float w, String label, String value, boolean strong) throws IOException {
        p.box(x, p.y() - 34, w, 44, strong);
        p.textAt(REGULAR, 8, x + 10, p.y() - 4, label.toUpperCase());
        p.textAt(strong ? BOLD : BOLD, 15, x + 10, p.y() - 24, value);
    }

    private void total(Page p, float w, String label, String value) throws IOException {
        p.moveDown(4);
        p.right(BOLD, 9.5f, MARGIN + w, label + " : " + value, p.y());
        p.moveDown(10);
    }

    private void table(Page p, List<Col> cols, List<String[]> rows, String empty) throws IOException {
        p.moveDown(16);
        header(p, cols);
        if (rows.isEmpty()) {
            p.text(REGULAR, 9, MARGIN + 4, empty);
            p.moveDown(16);
            return;
        }
        for (String[] r : rows) {
            // Une ligne coupee par un saut de page serait illisible : on repousse la ligne
            // entiere sur la page suivante, et on y reimprime les intitules de colonnes.
            if (p.y() < BOTTOM + 24) { p.newPage(); header(p, cols); }
            float x = MARGIN;
            for (int i = 0; i < cols.size(); i++) {
                Col c = cols.get(i);
                String v = fit(r[i], REGULAR, 9, c.width() - 8);
                if (c.right()) p.right(REGULAR, 9, x + c.width() - 4, v, p.y());
                else p.textAt(REGULAR, 9, x + 4, p.y(), v);
                x += c.width();
            }
            // Le filet se pose dans le blanc sous la ligne, avant de descendre : trace
            // apres le deplacement, il tomberait au milieu des lettres de la ligne suivante,
            // et sur la mauvaise page quand le deplacement en ouvre une.
            p.ruleLight(MARGIN, MARGIN + width(cols), p.y() - 5.5f);
            p.moveDown(15);
        }
    }

    private void header(Page p, List<Col> cols) throws IOException {
        float x = MARGIN;
        for (Col c : cols) {
            if (c.right()) p.right(BOLD, 8, x + c.width() - 4, c.title().toUpperCase(), p.y());
            else p.textAt(BOLD, 8, x + 4, p.y(), c.title().toUpperCase());
            x += c.width();
        }
        p.moveDown(5);
        p.rule(MARGIN, MARGIN + width(cols));
        p.moveDown(13);
    }

    private static float width(List<Col> cols) {
        float w = 0;
        for (Col c : cols) w += c.width();
        return w;
    }

    // ---------- utilitaires ----------

    private static String name(Company c) {
        return c.getTradeName() != null && !c.getTradeName().isBlank() ? c.getTradeName() : c.getName();
    }

    private static String join(String sep, String... parts) {
        StringBuilder b = new StringBuilder();
        for (String s : parts) if (s != null && !s.isBlank()) b.append(b.isEmpty() ? "" : sep).append(s.trim());
        return b.toString();
    }

    private static String money(BigDecimal v, int dec, String cur) { return ReceiptRenderer.money(v, dec) + " " + cur; }

    private static String qty(BigDecimal q) {
        if (q == null) return "";
        return q.stripTrailingZeros().scale() <= 0 ? q.stripTrailingZeros().toPlainString() : q.toPlainString();
    }

    private static String period(OffsetDateTime from, OffsetDateTime to) {
        if (from == null && to == null) return "depuis l'origine du compte";
        if (from == null) return "jusqu'au " + to.atZoneSameInstant(TZ).format(DATE);
        if (to == null) return "à partir du " + from.atZoneSameInstant(TZ).format(DATE);
        return "du " + from.atZoneSameInstant(TZ).format(DATE) + " au " + to.atZoneSameInstant(TZ).format(DATE);
    }

    /** Tronque avec des points de suite plutôt que de laisser un texte déborder sur la colonne voisine. */
    private static String fit(String s, PDFont f, float size, float max) throws IOException {
        String t = safe(s);
        if (textWidth(f, size, t) <= max) return t;
        while (t.length() > 1 && textWidth(f, size, t + "…") > max) t = t.substring(0, t.length() - 1);
        return t + "...";
    }

    private static float textWidth(PDFont f, float size, String s) throws IOException {
        return f.getStringWidth(safe(s)) / 1000 * size;
    }

    /**
     * Les polices standard d'un PDF n'encodent que le latin-1 : un tiret cadratin ou une
     * apostrophe typographique — fréquents dans des noms saisis au clavier — feraient
     * échouer la génération entière. On les ramène à leur équivalent simple.
     */
    static String safe(String s) {
        if (s == null) return "";
        String t = s.replace('’', '\'').replace('‘', '\'')
                .replace('“', '"').replace('”', '"')
                .replace('–', '-').replace('—', '-')
                .replace("…", "...").replace(' ', ' ')
                .replace("€", "EUR").replace("•", "-");
        StringBuilder b = new StringBuilder(t.length());
        for (char c : t.toCharArray()) b.append((c >= 32 && c <= 126) || (c >= 160 && c <= 255) ? c : '?');
        return b.toString();
    }

    /** Numérote les pages une fois leur nombre connu. */
    private void paginate(PDDocument doc) throws IOException {
        int n = doc.getNumberOfPages();
        for (int i = 0; i < n; i++) {
            PDPage page = doc.getPage(i);
            try (PDPageContentStream cs = new PDPageContentStream(doc, page, PDPageContentStream.AppendMode.APPEND, true, true)) {
                String label = "Page " + (i + 1) + " / " + n;
                float x = PDRectangle.A4.getWidth() - MARGIN - textWidth(REGULAR, 8, label);
                cs.beginText(); cs.setFont(REGULAR, 8); cs.newLineAtOffset(x, 28); cs.showText(label); cs.endText();
            }
        }
    }

    /** Curseur d'écriture : suit la position verticale et enchaîne les pages tout seul. */
    private static final class Page {
        private final PDDocument doc;
        private PDPageContentStream cs;
        private float y;

        Page(PDDocument doc) throws IOException { this.doc = doc; newPage(); }

        float y() { return y; }

        void newPage() throws IOException {
            if (cs != null) cs.close();
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            cs = new PDPageContentStream(doc, page);
            y = PDRectangle.A4.getHeight() - MARGIN;
        }

        void close() throws IOException { if (cs != null) { cs.close(); cs = null; } }

        void moveDown(float d) throws IOException {
            y -= d;
            if (y < BOTTOM) newPage();
        }

        void text(PDFont f, float size, float x, String s) throws IOException { textAt(f, size, x, y, s); }

        void textAt(PDFont f, float size, float x, float yy, String s) throws IOException {
            cs.beginText(); cs.setFont(f, size); cs.newLineAtOffset(x, yy); cs.showText(safe(s)); cs.endText();
        }

        void right(PDFont f, float size, float xEnd, String s, float yy) throws IOException {
            textAt(f, size, xEnd - textWidth(f, size, s), yy, s);
        }

        void section(PDFont f, float size, float x, String s) throws IOException {
            if (y < BOTTOM + 90) newPage();      // un titre seul en bas de page n'aide personne
            text(f, size, x, s);
        }

        void rule(float x1, float x2) throws IOException {
            cs.setLineWidth(.8f); cs.setStrokingColor(.16f, .16f, .16f);
            cs.moveTo(x1, y); cs.lineTo(x2, y); cs.stroke();
        }

        void ruleLight(float x1, float x2, float yy) throws IOException {
            cs.setLineWidth(.4f); cs.setStrokingColor(.80f, .80f, .80f);
            cs.moveTo(x1, yy); cs.lineTo(x2, yy); cs.stroke();
        }

        void box(float x, float yy, float w, float h, boolean strong) throws IOException {
            cs.setLineWidth(strong ? 1f : .6f);
            float g = strong ? .16f : .75f;
            cs.setStrokingColor(g, g, g);
            cs.addRect(x, yy, w, h); cs.stroke();
        }
    }
}
