package com.poscaisse.printing;

import com.poscaisse.domain.*;
import com.poscaisse.dto.AdminDtos.ReceiptTemplateDto;
import com.poscaisse.dto.AdminDtos.ReceiptTemplateRequest;
import com.poscaisse.dto.OrderDtos.PrintJobDto;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import com.poscaisse.service.Mappers;
import com.poscaisse.service.SettingsService;
import com.poscaisse.audit.AuditService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;

/**
 * Routes an order to print destinations (customer receipt + preparation tickets) and stores PrintJobs.
 * V1 transport = browser printing of the stored text; the PrintJob queue is the hook for an ESC/POS agent later.
 */
@Service @RequiredArgsConstructor
public class PrintService {
    private final PrintJobRepo jobRepo;
    private final PrintDestinationRepo destinationRepo;
    private final ReceiptTemplateRepo templateRepo;
    private final CompanyRepo companyRepo;
    private final ReceiptRenderer renderer;
    private final SettingsService settings;
    private final ObjectMapper objectMapper;
    private final AuditService audit;

    public ReceiptTemplate activeTemplate() {
        String code = settings.get(SettingsService.RECEIPT_TEMPLATE);
        return templateRepo.findByCode(code == null ? "DEFAULT" : code).or(() -> templateRepo.findAll().stream().findFirst()).orElse(null);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public List<PrintJob> createJobs(SaleOrder order, boolean duplicate) {
        Company company = companyRepo.findAll().stream().findFirst().orElse(null);
        ReceiptTemplate t = activeTemplate();
        boolean tax = settings.getBoolean(SettingsService.TAX_ENABLED);
        List<PrintJob> jobs = new ArrayList<>();
        List<PrintDestination> dests = destinationRepo.findAllByOrderBySortOrderAscIdAsc().stream().filter(PrintDestination::isActive).toList();
        boolean customerDone = false;
        for (PrintDestination d : dests) {
            if (d.getCopies() <= 0) continue;
            if (d.getKind() == Enums.DestinationKind.CUSTOMER) {
                if (customerDone) continue;
                customerDone = true;
                jobs.add(job(order, d, "Ticket client", renderer.customerReceipt(order, company, t, duplicate, tax), duplicate));
            } else {
                List<OrderLine> lines = order.getLines().stream().filter(l -> l.getParentLine() == null && routesTo(l, d)).toList();
                if (lines.isEmpty()) continue;
                jobs.add(job(order, d, d.getName(), renderer.prepTicket(order, lines, d, t, company, duplicate), duplicate));
            }
        }
        if (!customerDone) { // no CUSTOMER destination configured: still produce a receipt
            PrintJob j = new PrintJob();
            j.setOrder(order); j.setDestinationCode("CLIENT"); j.setTitle("Ticket client"); j.setCopies(1); j.setDuplicate(duplicate);
            j.setContent(renderer.customerReceipt(order, company, t, duplicate, tax));
            jobs.add(0, jobRepo.save(j));
        }
        return jobs;
    }

    private PrintJob job(SaleOrder order, PrintDestination d, String title, String content, boolean duplicate) {
        PrintJob j = new PrintJob();
        j.setOrder(order); j.setDestination(d); j.setDestinationCode(d.getCode()); j.setTitle(title); j.setCopies(d.getCopies());
        j.setContent(content); j.setDuplicate(duplicate);
        return jobRepo.save(j);
    }

    /** A line routes to a destination if its product (or any menu component's product) is linked to it, else via its category. */
    static boolean routesTo(OrderLine l, PrintDestination d) {
        if (productRoutes(l.getProduct(), d)) return true;
        for (OrderLine c : l.getComponents()) if (productRoutes(c.getProduct(), d)) return true;
        return false;
    }

    private static boolean productRoutes(Product p, PrintDestination d) {
        if (p == null) return false;
        if (!p.getPrintDestinations().isEmpty()) return p.getPrintDestinations().stream().anyMatch(x -> x.getId().equals(d.getId()));
        Category c = p.getCategory();
        return c != null && c.getPrintDestination() != null && c.getPrintDestination().getId().equals(d.getId());
    }

    @Transactional(readOnly = true)
    public List<PrintJobDto> jobsForOrder(Long orderId) { return jobRepo.findByOrderIdOrderByIdAsc(orderId).stream().map(Mappers::printJob).toList(); }

    @Transactional(readOnly = true)
    public List<PrintJobDto> pending() { return jobRepo.findTop100ByStatusOrderByIdAsc(Enums.PrintJobStatus.PENDING).stream().map(Mappers::printJob).toList(); }

    @Transactional
    public void markPrinted(List<Long> ids, boolean failed) {
        for (Long id : ids) jobRepo.findById(id).ifPresent(j -> {
            j.setStatus(failed ? Enums.PrintJobStatus.FAILED : Enums.PrintJobStatus.PRINTED);
            j.setPrintedAt(OffsetDateTime.now());
            jobRepo.save(j);
        });
    }

    // ---------- templates ----------
    @Transactional(readOnly = true)
    public List<ReceiptTemplateDto> templates() { return templateRepo.findAll().stream().map(this::dto).toList(); }

    @Transactional
    public ReceiptTemplateDto saveTemplate(String code, ReceiptTemplateRequest r) {
        ReceiptTemplate t = templateRepo.findByCode(code).orElseGet(() -> { ReceiptTemplate n = new ReceiptTemplate(); n.setCode(code); n.setName(code); return n; });
        if (r.name() != null) t.setName(r.name());
        if (r.paperWidth() != null) t.setPaperWidth(r.paperWidth() <= 58 ? 58 : 80);
        if (r.fontSize() != null) t.setFontSize(Math.max(8, Math.min(20, r.fontSize())));
        if (r.marginMm() != null) t.setMarginMm(Math.max(0, Math.min(15, r.marginMm())));
        if (r.showLogo() != null) t.setShowLogo(r.showLogo());
        t.setHeaderText(r.headerText());
        t.setFooterText(r.footerText());
        if (r.config() != null) {
            try { t.setConfigJson(objectMapper.writeValueAsString(r.config())); } catch (Exception e) { throw new BusinessException("Configuration de ticket invalide."); }
        }
        t.setUpdatedAt(OffsetDateTime.now());
        audit.log("RECEIPT_TEMPLATE_UPDATE", "ReceiptTemplate", code, null);
        return dto(templateRepo.save(t));
    }

    public ReceiptTemplateDto dto(ReceiptTemplate t) {
        return new ReceiptTemplateDto(t.getId(), t.getCode(), t.getName(), t.getPaperWidth(), t.getFontSize(), t.getMarginMm(), t.isShowLogo(),
                t.getHeaderText(), t.getFooterText(), renderer.config(t));
    }

    /** Renders a sample receipt with a transient template (for the live preview in settings). */
    @Transactional(readOnly = true)
    public Map<String, Object> preview(ReceiptTemplateRequest r, SaleOrder sample) {
        ReceiptTemplate t = new ReceiptTemplate();
        ReceiptTemplate base = activeTemplate();
        if (base != null) { t.setPaperWidth(base.getPaperWidth()); t.setFontSize(base.getFontSize()); t.setMarginMm(base.getMarginMm()); t.setShowLogo(base.isShowLogo()); t.setHeaderText(base.getHeaderText()); t.setFooterText(base.getFooterText()); t.setConfigJson(base.getConfigJson()); }
        if (r != null) {
            if (r.paperWidth() != null) t.setPaperWidth(r.paperWidth() <= 58 ? 58 : 80);
            if (r.fontSize() != null) t.setFontSize(r.fontSize());
            if (r.marginMm() != null) t.setMarginMm(r.marginMm());
            if (r.showLogo() != null) t.setShowLogo(r.showLogo());
            if (r.headerText() != null) t.setHeaderText(r.headerText());
            if (r.footerText() != null) t.setFooterText(r.footerText());
            if (r.config() != null) { try { t.setConfigJson(objectMapper.writeValueAsString(r.config())); } catch (Exception ignored) {} }
        }
        Company company = companyRepo.findAll().stream().findFirst().orElse(null);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("content", renderer.customerReceipt(sample, company, t, false, settings.getBoolean(SettingsService.TAX_ENABLED)));
        out.put("paperWidth", t.getPaperWidth()); out.put("fontSize", t.getFontSize()); out.put("marginMm", t.getMarginMm());
        out.put("showLogo", t.isShowLogo()); out.put("logoData", company == null ? null : company.getLogoData());
        return out;
    }
}
